# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# LAUNCH AN ELASTICACHE CLUSTER TO RUN MEMCACHED
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ----------------------------------------------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ----------------------------------------------------------------------------------------------------------------------

provider "aws" {
  # The AWS region in which all resources will be created
  region = var.aws_region

  # Provider version 2.X series is the latest, but has breaking changes with 1.X series.
  version = "~> 2.6"

  # Only these AWS Account IDs may be operated on by this template
  allowed_account_ids = [var.aws_account_id]
}

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE REMOTE STATE STORAGE
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}

  # Only allow this Terraform version. Note that if you upgrade to a newer version, Terraform won't allow you to use an
  # older version, so when you upgrade, you should upgrade everyone on your team and your CI servers all at once.
  required_version = "= 0.12.9"
}

# ----------------------------------------------------------------------------------------------------------------------
# LAUNCH THE ELASTICACHE CLUSTER
# ----------------------------------------------------------------------------------------------------------------------

module "memcached" {
  source = "git::git@github.com:gruntwork-io/module-cache.git//modules/memcached?ref=v0.6.1"

  name              = var.name
  memcached_version = var.memcached_version
  port              = var.port

  instance_type   = var.instance_type
  num_cache_nodes = var.num_cache_nodes
  az_mode         = var.az_mode

  # Run in the private persistence subnets of the VPC and only allow incoming connections from the private app subnets
  vpc_id                             = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids                         = data.terraform_remote_state.vpc.outputs.private_persistence_subnet_ids
  allow_connections_from_cidr_blocks = data.terraform_remote_state.vpc.outputs.private_app_subnet_cidr_blocks

  apply_immediately = var.apply_immediately
}

# ---------------------------------------------------------------------------------------------------------------------
# ADD CLOUDWATCH ALARMS FOR THE ELASTICACHE CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "memcached_alarms" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/alarms/elasticache-memcached-alarms?ref=v0.13.2"

  cache_cluster_id     = module.memcached.cache_cluster_id
  cache_node_ids       = module.memcached.cache_node_ids
  num_cache_node_ids   = var.num_cache_nodes
  alarm_sns_topic_arns = [data.terraform_remote_state.sns_region.outputs.arn]
}

# ----------------------------------------------------------------------------------------------------------------------
# PULL ALL VPC DATA FROM THE REMOTE STATE STORED BY THE VPC TEMPLATES
# These templates run on top of the VPCs created by the VPC templates, which store their Terraform state files in an S3
# bucket using remote state storage.
# ----------------------------------------------------------------------------------------------------------------------

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/${var.vpc_name}/vpc/terraform.tfstate"
  }
}

data "terraform_remote_state" "sns_region" {
  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/_global/sns-topics/terraform.tfstate"
  }
}

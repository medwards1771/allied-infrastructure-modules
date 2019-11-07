# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# LAUNCH A RDS CLUSTER
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE RDS CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "database" {
  source = "git::git@github.com:gruntwork-io/module-data-storage.git//modules/rds?ref=v0.9.0"

  name           = var.name
  db_name        = var.db_name
  engine         = var.engine
  engine_version = var.engine_version
  port           = var.port
  license_model  = var.license_model

  master_username = var.master_username
  master_password = var.master_password

  # Run in the private persistence subnets and only allow incoming connections from the private app subnets
  vpc_id                             = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids                         = data.terraform_remote_state.vpc.outputs.private_persistence_subnet_ids
  allow_connections_from_cidr_blocks = data.terraform_remote_state.vpc.outputs.private_app_subnet_cidr_blocks

  allow_connections_from_security_groups = (
    var.allow_connections_from_openvpn_server
    ? [data.terraform_remote_state.openvpn_server.outputs.security_group_id]
    : []
  )

  instance_type     = var.instance_type
  allocated_storage = var.allocated_storage
  num_read_replicas = var.num_read_replicas

  storage_encrypted = var.storage_encrypted
  kms_key_arn       = data.terraform_remote_state.kms_master_key.outputs.key_arn

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  apply_immediately       = var.apply_immediately
}

# ---------------------------------------------------------------------------------------------------------------------
# ADD CLOUDWATCH ALARMS FOR THE RDS INSTANCES
# ---------------------------------------------------------------------------------------------------------------------

module "rds_alarms" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/alarms/rds-alarms?ref=v0.13.2"

  rds_instance_ids     = local.rds_database_ids
  num_rds_instance_ids = 1 + var.num_read_replicas
  alarm_sns_topic_arns = [data.terraform_remote_state.sns_region.outputs.arn]

  too_many_db_connections_threshold  = var.too_many_db_connections_threshold
  high_cpu_utilization_threshold     = var.high_cpu_utilization_threshold
  high_cpu_utilization_period        = var.high_cpu_utilization_period
  low_memory_available_threshold     = var.low_memory_available_threshold
  low_memory_available_period        = var.low_memory_available_period
  low_disk_space_available_threshold = var.low_disk_space_available_threshold
  low_disk_space_available_period    = var.low_disk_space_available_period
  enable_perf_alarms                 = var.enable_perf_alarms
}

module "metric_widget_rds_cpu_usage" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/metrics/cloudwatch-dashboard-metric-widget?ref=v0.13.2"

  period = 60
  stat   = "Average"
  title  = "${title(var.engine)} CPUUtilization"

  metrics = [
    for id in local.rds_database_ids : ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", id]
  ]
}

module "metric_widget_rds_memory" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/metrics/cloudwatch-dashboard-metric-widget?ref=v0.13.2"

  period = 60
  stat   = "Minimum"
  title  = "${title(var.engine)} FreeableMemory"

  metrics = [
    for id in local.rds_database_ids : ["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", id]
  ]
}

module "metric_widget_rds_disk_space" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/metrics/cloudwatch-dashboard-metric-widget?ref=v0.13.2"

  period = 60
  stat   = "Minimum"
  title  = "${title(var.engine)} FreeStorageSpace"

  metrics = [
    for id in local.rds_database_ids : ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", id]
  ]
}

module "metric_widget_rds_db_connections" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/metrics/cloudwatch-dashboard-metric-widget?ref=v0.13.2"

  period = 60
  stat   = "Maximum"
  title  = "${title(var.engine)} DatabaseConnections"

  metrics = [
    for id in local.rds_database_ids : ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", id]
  ]
}

module "metric_widget_rds_read_latency" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/metrics/cloudwatch-dashboard-metric-widget?ref=v0.13.2"

  period = 60
  stat   = "Average"
  title  = "${title(var.engine)} ReadLatency"

  metrics = [
    for id in local.rds_database_ids : ["AWS/RDS", "ReadLatency", "DBInstanceIdentifier", id]
  ]
}

module "metric_widget_rds_write_latency" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/metrics/cloudwatch-dashboard-metric-widget?ref=v0.13.2"

  period = 60
  stat   = "Average"
  title  = "${title(var.engine)} WriteLatency"

  metrics = [
    for id in local.rds_database_ids : ["AWS/RDS", "WriteLatency", "DBInstanceIdentifier", id]
  ]
}

locals {
  rds_database_ids = concat([module.database.primary_id], module.database.read_replica_ids)
}

# ---------------------------------------------------------------------------------------------------------------------
# PULL DATA FROM OTHER TERRAFORM TEMPLATES USING TERRAFORM REMOTE STATE
# These templates use Terraform remote state to access data from a number of other Terraform templates, all of which
# store their state in S3 buckets.
# ---------------------------------------------------------------------------------------------------------------------

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/${var.vpc_name}/vpc/terraform.tfstate"
  }
}

data "terraform_remote_state" "openvpn_server" {
  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/mgmt/openvpn-server/terraform.tfstate"
  }
}

data "terraform_remote_state" "kms_master_key" {
  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/_global/${var.terraform_state_kms_master_key}/terraform.tfstate"
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

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  # The AWS region in which all resources will be created
  region = var.aws_region

  # Provider version 2.X series is the latest, but has breaking changes with 1.X series.
  version = "~> 2.6"
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
# CREATE DASHBOARD
# ---------------------------------------------------------------------------------------------------------------------

module "dashboard" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/metrics/cloudwatch-dashboard?ref=v0.13.2"

  aws_region = var.aws_region
  name       = var.name

  widgets = [
    data.terraform_remote_state.ecs_cluster.outputs.metric_widget_ecs_cluster_cpu_usage,
    data.terraform_remote_state.ecs_cluster.outputs.metric_widget_ecs_cluster_memory_usage,
    data.terraform_remote_state.sample_app_frontend.outputs.metric_widget_ecs_service_cpu_usage,
    data.terraform_remote_state.sample_app_frontend.outputs.metric_widget_ecs_service_memory_usage,
    data.terraform_remote_state.sample_app_backend.outputs.metric_widget_ecs_service_cpu_usage,
    data.terraform_remote_state.sample_app_backend.outputs.metric_widget_ecs_service_memory_usage,
    data.terraform_remote_state.sample_app_frontend.outputs.metric_widget_target_group_host_count,
    data.terraform_remote_state.sample_app_frontend.outputs.metric_widget_target_group_request_count,
    data.terraform_remote_state.sample_app_frontend.outputs.metric_widget_target_group_connection_error_count,
    data.terraform_remote_state.sample_app_frontend.outputs.metric_widget_target_group_response_time,
    data.terraform_remote_state.sample_app_frontend.outputs.metric_widget_target_group_4xx_count,
    data.terraform_remote_state.sample_app_frontend.outputs.metric_widget_target_group_5xx_count,
    data.terraform_remote_state.sample_app_backend.outputs.metric_widget_target_group_host_count,
    data.terraform_remote_state.sample_app_backend.outputs.metric_widget_target_group_request_count,
    data.terraform_remote_state.sample_app_backend.outputs.metric_widget_target_group_connection_error_count,
    data.terraform_remote_state.sample_app_backend.outputs.metric_widget_target_group_response_time,
    data.terraform_remote_state.sample_app_backend.outputs.metric_widget_target_group_4xx_count,
    data.terraform_remote_state.sample_app_backend.outputs.metric_widget_target_group_5xx_count,
    data.terraform_remote_state.rds.outputs.metric_widget_rds_cpu_usage,
    data.terraform_remote_state.rds.outputs.metric_widget_rds_memory,
    data.terraform_remote_state.rds.outputs.metric_widget_rds_disk_space,
    data.terraform_remote_state.rds.outputs.metric_widget_rds_db_connections,
    data.terraform_remote_state.rds.outputs.metric_widget_rds_read_latency,
    data.terraform_remote_state.rds.outputs.metric_widget_rds_write_latency,
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# PULL DATA FROM OTHER TERRAFORM TEMPLATES USING TERRAFORM REMOTE STATE
# These templates use Terraform remote state to access data from a number of other Terraform templates, all of which
# store their state in S3 buckets.
# ---------------------------------------------------------------------------------------------------------------------

data "terraform_remote_state" "rds" {
  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/${var.vpc_name}/data-stores/postgres/terraform.tfstate"
  }
}

data "terraform_remote_state" "ecs_cluster" {
  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/${var.vpc_name}/services/ecs-cluster/terraform.tfstate"
  }
}

data "terraform_remote_state" "sample_app_frontend" {
  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/${var.vpc_name}/services/sample-app-frontend/terraform.tfstate"
  }
}

data "terraform_remote_state" "sample_app_backend" {
  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/${var.vpc_name}/services/sample-app-backend/terraform.tfstate"
  }
}

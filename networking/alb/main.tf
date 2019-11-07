# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY AN APPLICATION LOAD BALANCER (ALB)
# A single ALB can be shared among multiple ECS Clusters, ECS Services or Auto Scaling Groups. For this reason, it's
# created separately from those resources.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------

provider "aws" {
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
# CREATE AN ALB
# ---------------------------------------------------------------------------------------------------------------------

module "alb" {
  source = "git::git@github.com:gruntwork-io/module-load-balancer.git//modules/alb?ref=v0.14.1"

  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region

  # You can find the list of policies here: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies
  ssl_policy = "ELBSecurityPolicy-2016-08"

  alb_name         = var.alb_name
  environment_name = data.terraform_remote_state.vpc.outputs.vpc_name
  is_internal_alb  = var.is_internal_alb

  http_listener_ports = var.http_listener_ports

  https_listener_ports_and_ssl_certs     = var.https_listener_ports_and_ssl_certs
  https_listener_ports_and_ssl_certs_num = var.https_listener_ports_and_ssl_certs_num

  https_listener_ports_and_acm_ssl_certs     = var.https_listener_ports_and_acm_ssl_certs
  https_listener_ports_and_acm_ssl_certs_num = var.https_listener_ports_and_acm_ssl_certs_num

  allow_inbound_from_cidr_blocks = (
    var.is_internal_alb
    ? concat(var.allow_inbound_from_cidr_blocks, [data.terraform_remote_state.vpc.outputs.vpc_cidr_block])
    : var.allow_inbound_from_cidr_blocks
  )
  allow_inbound_from_security_group_ids     = [data.terraform_remote_state.openvpn_server.outputs.security_group_id]
  allow_inbound_from_security_group_ids_num = 1

  vpc_id         = data.terraform_remote_state.vpc.outputs.vpc_id
  vpc_subnet_ids = (
    var.is_internal_alb
    ? data.terraform_remote_state.vpc.outputs.private_app_subnet_ids
    : data.terraform_remote_state.vpc.outputs.public_subnet_ids
  )

  enable_alb_access_logs         = true
  alb_access_logs_s3_bucket_name = module.alb_access_logs_bucket.s3_bucket_name
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE S3 BUCKET USED TO STORE THE ALB'S LOGS
# ---------------------------------------------------------------------------------------------------------------------

# Create an S3 Bucket to store ALB access logs.
module "alb_access_logs_bucket" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/logs/load-balancer-access-logs?ref=v0.13.2"

  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region

  # Try to do some basic cleanup to get a valid S3 bucket name: the name must be lower case and can only contain
  # lowercase letters, numbers, and hyphens. For the full rules, see:
  # http://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html#bucketnamingrules
  s3_bucket_name = (
    var.access_logs_s3_bucket_name != null
    ? var.access_logs_s3_bucket_name
    : "alb-${lower(replace(var.alb_name, "_", "-"))}-access-logs"
  )
  s3_logging_prefix = var.alb_name

  num_days_after_which_archive_log_data = var.num_days_after_which_archive_log_data
  num_days_after_which_delete_log_data  = var.num_days_after_which_delete_log_data

  force_destroy = var.force_destroy
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A DNS RECORD USING ROUTE 53
# ---------------------------------------------------------------------------------------------------------------------

# The ECS Service's endpoint will point to the ELB.
resource "aws_route53_record" "dns_record" {
  count = var.create_route53_entry ? 1 : 0

  zone_id = element(
    concat(
      data.terraform_remote_state.route53_private.*.outputs.internal_services_hosted_zone_id,
      data.terraform_remote_state.route53_public.*.outputs.primary_domain_hosted_zone_id,
    ),
    0,
  )
  name = var.domain_name
  type = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_hosted_zone_id
    evaluate_target_health = true
  }
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

data "terraform_remote_state" "route53_private" {
  count = var.create_route53_entry && var.is_internal_alb ? 1 : 0

  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/${var.vpc_name}/networking/route53-private/terraform.tfstate"
  }
}

data "terraform_remote_state" "route53_public" {
  count = var.create_route53_entry && (! var.is_internal_alb) ? 1 : 0

  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "_global/route53-public/terraform.tfstate"
  }
}

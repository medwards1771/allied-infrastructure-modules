# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# LAUNCH AN OPENVPN SERVER
# The OpenVPN Server is the sole point of entry to the network. This way, we can make all other servers inaccessible
# from the public Internet and focus our efforts on locking down the OpenVPN Server.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ---------------------------------------------------------------------------------------------------------------------

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
# LAUNCH THE OPENVPN SERVER
# ---------------------------------------------------------------------------------------------------------------------

module "openvpn" {
  source = "git::git@github.com:gruntwork-io/module-openvpn.git//modules/openvpn-server?ref=v0.9.2"

  aws_region     = var.aws_region
  aws_account_id = var.aws_account_id

  name = var.name

  instance_type = var.instance_type
  ami           = var.ami
  user_data     = data.template_file.user_data.rendered

  request_queue_name    = var.request_queue_name
  revocation_queue_name = var.revocation_queue_name

  keypair_name       = var.keypair_name
  kms_key_arn        = data.terraform_remote_state.kms_master_key.outputs.key_arn
  backup_bucket_name = var.backup_bucket_name

  vpc_id    = data.terraform_remote_state.mgmt_vpc.outputs.vpc_id
  subnet_id = data.terraform_remote_state.mgmt_vpc.outputs.public_subnet_ids[0]

  external_account_arns = var.external_account_arns

  allow_ssh_from_cidr      = true
  allow_ssh_from_cidr_list = var.allow_ssh_from_cidr_list

  backup_bucket_force_destroy = var.force_destroy
}

# ---------------------------------------------------------------------------------------------------------------------
# ASSEMBLE A LIST OF IP ADDRESS RANGES THAT WILL BE ROUTED OVER VPN
# We add the CIDR blocks of all the VPCs here so that all requests to VPC IP addresses are routed over VPN.
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "vpn_routes" {
  count    = length(data.template_file.all_vpc_cidr_blocks.*.rendered)
  template = "${cidrhost(data.template_file.all_vpc_cidr_blocks.*.rendered[count.index], 0)} ${cidrnetmask(data.template_file.all_vpc_cidr_blocks.*.rendered[count.index])}"
}

data "template_file" "all_vpc_cidr_blocks" {
  count    = length(data.terraform_remote_state.other_vpcs.*.outputs.vpc_cidr_block) + 1
  template = element(concat(data.terraform_remote_state.other_vpcs.*.outputs.vpc_cidr_block, [data.terraform_remote_state.mgmt_vpc.outputs.vpc_cidr_block]), count.index)
}

# ---------------------------------------------------------------------------------------------------------------------
# THE USER DATA SCRIPT THAT WILL WILL RUN ON THE OPENVPN SERVER DURING BOOT
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data" {
  template = file("${path.module}/user-data/user-data.sh")

  vars = {
    backup_bucket_name = module.openvpn.backup_bucket_name
    kms_key_id         = data.terraform_remote_state.kms_master_key.outputs.key_id

    key_size             = 4096
    ca_expiration_days   = 3650
    cert_expiration_days = 3650

    ca_country  = var.ca_country
    ca_state    = var.ca_state
    ca_locality = var.ca_locality
    ca_org      = var.ca_org
    ca_org_unit = var.ca_org_unit
    ca_email    = var.ca_email

    eip_id = module.openvpn.elastic_ip

    request_queue_url    = module.openvpn.client_request_queue
    revocation_queue_url = module.openvpn.client_revocation_queue
    queue_region         = var.aws_region

    vpn_subnet = var.vpn_subnet
    routes     = join(" ", formatlist("\"%s\"", data.template_file.vpn_routes.*.rendered))
    vpc_name       = data.terraform_remote_state.mgmt_vpc.outputs.vpc_name
    log_group_name = var.name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# GIVE SSH-GRUNT PERMISSIONS TO TALK TO IAM
# We add an IAM policy to our OpenVPN Server that allows ssh-grunt to make API calls to IAM to fetch IAM user and group
# data.
# ---------------------------------------------------------------------------------------------------------------------

module "iam_policies" {
  source = "git::git@github.com:gruntwork-io/module-security.git//modules/iam-policies?ref=v0.18.1"

  aws_account_id = var.aws_account_id

  # ssh-grunt is an automated app, so we can't use MFA with it
  iam_policy_should_require_mfa   = false
  trust_policy_should_require_mfa = false

  # Since our IAM users are defined in a separate AWS account, we need to give ssh-grunt permission to make API calls to
  # that account.
  allow_access_to_other_account_arns = [var.external_account_ssh_grunt_role_arn]
}

resource "aws_iam_role_policy" "ssh_grunt_permissions" {
  name = "ssh-grunt-permissions"
  role = module.openvpn.iam_role_id
  policy = module.iam_policies.allow_access_to_other_accounts[0]
}

# ---------------------------------------------------------------------------------------------------------------------
# ADD IAM POLICY THAT ALLOWS READING AND WRITING CLOUDWATCH METRICS
# ---------------------------------------------------------------------------------------------------------------------

module "cloudwatch_metrics" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/metrics/cloudwatch-custom-metrics-iam-policy?ref=v0.13.2"

  name_prefix = var.name
}

resource "aws_iam_policy_attachment" "attach_cloudwatch_metrics_policy" {
  name       = "attach-cloudwatch-metrics-policy"
  roles      = [module.openvpn.iam_role_id]
  policy_arn = module.cloudwatch_metrics.cloudwatch_metrics_policy_arn
}

# ------------------------------------------------------------------------------
# ADD IAM POLICY THAT ALLOWS CLOUDWATCH LOG AGGREGATION
# ------------------------------------------------------------------------------

module "cloudwatch_log_aggregation" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/logs/cloudwatch-log-aggregation-iam-policy?ref=v0.13.2"

  name_prefix = var.name
}

resource "aws_iam_policy_attachment" "attach_cloudwatch_log_aggregation_policy" {
  name       = "attach-cloudwatch-log-aggregation-policy"
  roles      = [module.openvpn.iam_role_id]
  policy_arn = module.cloudwatch_log_aggregation.cloudwatch_log_aggregation_policy_arn
}

# ---------------------------------------------------------------------------------------------------------------------
# ADD CLOUDWATCH ALARMS THAT GO OFF IF THE OPENVPN SERVER'S CPU, MEMORY, OR DISK USAGE GET TOO HIGH
# ---------------------------------------------------------------------------------------------------------------------

module "high_cpu_usage_alarms" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/alarms/asg-cpu-alarms?ref=v0.13.2"

  asg_names            = [module.openvpn.autoscaling_group_id]
  num_asg_names        = 1
  alarm_sns_topic_arns = [data.terraform_remote_state.sns_region.outputs.arn]
}

module "high_memory_usage_alarms" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/alarms/asg-memory-alarms?ref=v0.13.2"

  asg_names            = [module.openvpn.autoscaling_group_id]
  num_asg_names        = 1
  alarm_sns_topic_arns = [data.terraform_remote_state.sns_region.outputs.arn]
}

module "high_disk_usage_alarms" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/alarms/asg-disk-alarms?ref=v0.13.2"

  asg_names            = [module.openvpn.autoscaling_group_id]
  num_asg_names        = 1
  file_system          = "/dev/xvda1"
  mount_path           = "/"
  alarm_sns_topic_arns = [data.terraform_remote_state.sns_region.outputs.arn]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A DNS A RECORD FOR THE SERVER
# Create an A Record in Route 53 pointing to the IP of this server so you can connect to it using a nice domain name
# like foo.your-company.com.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route53_record" "openvpn" {
  count   = var.create_route53_entry ? 1 : 0
  zone_id = data.terraform_remote_state.route53_public.*.outputs.primary_domain_hosted_zone_id[0]
  name    = var.domain_name
  type    = "A"
  ttl     = "300"
  records = [module.openvpn.public_ip]
}

# ---------------------------------------------------------------------------------------------------------------------
# PULL MGMT VPC DATA FROM THE TERRAFORM REMOTE STATE
# These templates run on top of the VPCs created by the VPC templates, which store their Terraform state files in an S3
# bucket using remote state storage.
# ---------------------------------------------------------------------------------------------------------------------

data "terraform_remote_state" "mgmt_vpc" {
  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/${var.current_vpc_name}/vpc/terraform.tfstate"
  }
}

data "terraform_remote_state" "other_vpcs" {
  count = length(var.other_vpc_names)

  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/${element(var.other_vpc_names, count.index)}/vpc/terraform.tfstate"
  }
}

data "terraform_remote_state" "kms_master_key" {
  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/_global/kms-master-key/terraform.tfstate"
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

data "terraform_remote_state" "route53_public" {
  count   = var.create_route53_entry ? 1 : 0
  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "_global/route53-public/terraform.tfstate"
  }
}

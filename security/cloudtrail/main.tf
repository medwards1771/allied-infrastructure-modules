# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CONFIGURE CLOUDTRAIL TO LOG EVERY API CALL IN THIS AWS ACCOUNT
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
# ENABLE CLOUDTRAIL
# Setup a CloudTrail stream to track all API requests and store them in the specified S3 Bucket.
# To understand the meaning of each property, see the vars.tf file at https://goo.gl/kRx6WN.
# ---------------------------------------------------------------------------------------------------------------------

module "cloudtrail" {
  source = "git::git@github.com:gruntwork-io/module-security.git//modules/cloudtrail?ref=v0.18.1"

  aws_region     = var.aws_region
  aws_account_id = var.aws_account_id

  cloudtrail_trail_name = var.cloudtrail_trail_name
  s3_bucket_name        = var.s3_bucket_name

  num_days_after_which_archive_log_data = var.num_days_after_which_archive_log_data
  num_days_after_which_delete_log_data  = var.num_days_after_which_delete_log_data

  # Note that users with IAM permissions to CloudTrail can still view the last 7 days of data in the AWS Web Console!
  kms_key_user_iam_arns            = var.kms_key_user_iam_arns
  kms_key_administrator_iam_arns   = var.kms_key_administrator_iam_arns
  allow_cloudtrail_access_with_iam = var.allow_cloudtrail_access_with_iam

  # If you're writing CloudTrail logs to an existing S3 bucket in another AWS account, set this to true
  s3_bucket_already_exists = var.s3_bucket_already_exists

  # If external AWS accounts need to write CloudTrail logs to the S3 bucket in this AWS account, provide those
  # external AWS account IDs here
  external_aws_account_ids_with_write_access = var.external_aws_account_ids_with_write_access

  force_destroy = var.force_destroy
}

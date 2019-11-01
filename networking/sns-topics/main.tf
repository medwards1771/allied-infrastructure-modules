# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE SNS TOPICS
# When you want to send a notification on an event, it's useful to have a Simple Notification Service (SNS) Topic to
# which a message can be published. Operators can then manually subscribe to receive email or text message
# notifications when various events take place.
#
# IMPORTANT: You will not receive any notification that an SNS Topic has received a message unless you manually
# subscribe an email address or other endpoint to that SNS Topic.
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
# CREATE SNS TOPIC
# ---------------------------------------------------------------------------------------------------------------------

module "sns_topic" {
  source = "git::git@github.com:gruntwork-io/package-messaging.git//modules/sns?ref=v0.3.0"

  name                      = var.name
  display_name              = var.display_name
  allow_publish_accounts    = var.allow_publish_accounts
  allow_subscribe_accounts  = var.allow_subscribe_accounts
  allow_subscribe_protocols = var.allow_subscribe_protocols
}

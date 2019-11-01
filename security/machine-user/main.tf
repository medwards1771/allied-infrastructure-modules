# ---------------------------------------------------------------------------------------------------------------------
# CREATE A MACHINE USER THAT CAN BE USED FOR CI / CD BUILDS
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ---------------------------------------------------------------------------------------------------------------------

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
# CREATE THE USER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_user" "machine_user" {
  name = var.name
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH IAM PERMISSIONS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_user_policy" "machine_user_permissions" {
  count  = signum(length(var.allowed_iam_actions))
  user   = aws_iam_user.machine_user.name
  policy = data.aws_iam_policy_document.machine_user_permissions.json
}

data "aws_iam_policy_document" "machine_user_permissions" {
  statement {
    effect    = "Allow"
    actions   = var.allowed_iam_actions
    resources = ["*"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ADD TO IAM GROUPS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_group_membership" "machine_user_groups" {
  count = length(var.iam_groups)
  group = var.iam_groups[count.index]
  name  = "machine-user-groups-${count.index}"
  users = [aws_iam_user.machine_user.name]
}

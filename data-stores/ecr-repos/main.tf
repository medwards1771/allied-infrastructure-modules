# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ADD AN AMAZON EC2 CONTAINER REGISTRY REPO FOR EACH MICROSERVICE
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
# CREATE ECR REPOS
# Each Docker image that we run in our ECS Clusters will need an ECR Repo where its Docker Image is stored.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ecr_repository" "repos" {
  count = length(var.repo_names)
  name  = var.repo_names[count.index]
}

# ---------------------------------------------------------------------------------------------------------------------
# GIVE EXTERNAL ACCOUNTS ABILITY TO PUSH AND PULL IMAGES
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ecr_repository_policy" "external_account_access" {
  count = (
    length(var.external_account_ids_with_read_access) > 0 || length(var.external_account_ids_with_write_access) > 0
    ? length(var.repo_names)
    : 0
  )

  repository = aws_ecr_repository.repos.*.name[count.index]
  policy     = data.aws_iam_policy_document.external_account_access.json
}

data "aws_iam_policy_document" "external_account_access" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = formatlist("arn:aws:iam::%s:root", var.external_account_ids_with_read_access)
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
    ]
  }

  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = formatlist("arn:aws:iam::%s:root", var.external_account_ids_with_write_access)
    }

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
  }
}

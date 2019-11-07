# ---------------------------------------------------------------------------------------------------------------------
# CREATE A LAMBDA FUNCTION TO PROCESS IMAGES IN S3
# This function can download an image and return its base64-encoded contents.
# ---------------------------------------------------------------------------------------------------------------------

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
# CREATE THE LAMBDA FUNCTION
# ---------------------------------------------------------------------------------------------------------------------

module "lambda_s3" {
  source = "git::git@github.com:gruntwork-io/package-lambda.git//modules/lambda?ref=v0.6.0"

  name        = var.name
  description = "An example of how to process images in S3 with Lambda"

  source_path = "${path.module}/python"
  runtime     = "python2.7"
  handler     = "index.handler"

  timeout     = 30
  memory_size = 128
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN S3 BUCKET AND UPLOAD AN IMAGE FOR TESTING
# This is used for testing/demonstration. You do NOT need to copy this into your real-world use cases!
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "images" {
  bucket        = lower(var.bucket_name)
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_object" "gruntwork_logo" {
  bucket = aws_s3_bucket.images.id
  key    = "gruntwork-logo.png"
  source = "${path.module}/images/gruntwork-logo.png"
}

# ---------------------------------------------------------------------------------------------------------------------
# GIVE THE LAMBDA FUNCTION PERMISSIONS TO ACCESS THE S3 BUCKET
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role_policy" "access_s3_bucket" {
  role   = module.lambda_s3.iam_role_id
  policy = data.aws_iam_policy_document.access_s3_bucket.json
}

data "aws_iam_policy_document" "access_s3_bucket" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.images.arn}/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.images.arn}"]
  }
}

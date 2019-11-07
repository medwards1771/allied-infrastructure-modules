# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region to deploy to (e.g. us-east-1)"
  type        = string
}

variable "aws_account_id" {
  description = "The ID of the AWS Account in which to create resources."
  type        = string
}

variable "name" {
  description = "The name to use for the Lambda function"
  type        = string
}

variable "bucket_name" {
  description = "The name for the S3 bucket where we will store images for the Lambda function to process"
  type        = string
}

variable "force_destroy" {
  description = "Set to true to delete the contents of the sample S3 bucket when you run 'terraform destroy'."
  type        = bool
  default     = false
}

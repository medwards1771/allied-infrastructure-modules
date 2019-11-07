# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are required. A value must be passed in.
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
}

variable "aws_account_id" {
  description = "The ID of the AWS Account in which to create resources."
  type        = string
}

variable "name" {
  description = "The name for the machine user"
  type        = string
}

variable "allowed_iam_actions" {
  description = "The IAM actions this machine user is allowed to perform on all resources (e.g., ecr:*)"
  type        = list(string)
}

variable "iam_groups" {
  description = "The names of IAM groups the machine user should be added to"
  type        = list(string)
}

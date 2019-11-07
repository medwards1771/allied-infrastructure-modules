# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
}

variable "aws_account_id" {
  description = "The ID of the AWS Account in which to create resources."
  type        = string
}

variable "cloudtrail_trail_name" {
  description = "The name to assign to the CloudTrail 'trail' that will be used to track all API calls in your AWS account."
  type        = string
}

variable "s3_bucket_name" {
  description = "The name of the S3 Bucket where CloudTrail logs will be stored."
  type        = string
}

variable "num_days_after_which_archive_log_data" {
  description = "After this number of days, log files should be transitioned from S3 to Glacier. Enter 0 to never archive log data."
  type        = number
}

variable "num_days_after_which_delete_log_data" {
  description = "After this number of days, log files should be deleted from S3. Enter 0 to never delete log data."
  type        = number
}

variable "kms_key_administrator_iam_arns" {
  description = "All CloudTrail Logs will be encrypted with a KMS Key (a Customer Master Key) that governs access to write API calls older than 7 days and all read API calls. The IAM Users specified in this list will have rights to change who can access this extended log data."
  type        = list(string)
  # example = ["arn:aws:iam::<aws-account-id>:user/<iam-user-name>"]
}

variable "kms_key_user_iam_arns" {
  description = "All CloudTrail Logs will be encrypted with a KMS Key (a Customer Master Key) that governs access to write API calls older than 7 days and all read API calls. The IAM Users specified in this list will have read-only access to this extended log data."
  type        = list(string)
  # example = ["arn:aws:iam::<aws-account-id>:user/<iam-user-name>"]
}

variable "allow_cloudtrail_access_with_iam" {
  description = "If true, an IAM Policy that grants access to CloudTrail will be honored. If false, only the ARNs listed in var.kms_key_user_iam_arns will have access to CloudTrail and any IAM Policy grants will be ignored. (true or false)"
  type        = bool
}

variable "s3_bucket_already_exists" {
  description = "If set to true, that means the S3 bucket you're using already exists, and does not need to be created. This is especially useful when using CloudTrail with multiple AWS accounts, with a common S3 bucket shared by all of them."
  type        = bool
  default     = false
}

variable "external_aws_account_ids_with_write_access" {
  description = "A list of external AWS accounts that should be given write access for CloudTrail logs to this S3 bucket. This is useful when aggregating CloudTrail logs for multiple AWS accounts in one common S3 bucket."
  type        = list(string)
  default     = []
}

variable "force_destroy" {
  description = "If set to true, when you run 'terraform destroy', delete all objects from the bucket so that the bucket can be destroyed without error. Warning: these objects are not recoverable so only use this if you're absolutely sure you want to permanently delete everything!"
  type        = bool
  default     = false
}

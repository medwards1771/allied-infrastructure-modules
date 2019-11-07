# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables must be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
}

variable "aws_account_id" {
  description = "The ID of the AWS Account in which to create resources."
  type        = string
}

variable "should_require_mfa" {
  description = "Should we require that all IAM Users use Multi-Factor Authentication for both AWS API calls and the AWS Web Console? (true or false)"
  type        = bool
}

variable "dev_permitted_services" {
  description = "A list of AWS services for which the developers from the accounts in var.allow_dev_access_from_other_account_arns will receive full permissions. See https://goo.gl/ZyoHlz to find the IAM Service name. For example, to grant developers access only to EC2 and Amazon Machine Learning, use the value [\"ec2\",\"machinelearning\"]. Do NOT add iam to the list of services, or that will grant Developers de facto admin access."
  type        = list(string)
  default     = []
}

variable "allow_read_only_access_from_other_account_arns" {
  description = "A list of IAM ARNs from other AWS accounts that will be allowed read-only access to this account."
  type        = list(string)
  # Example:
  # default = [
  #   "arn:aws:iam::123445678910:root"
  # ]
}

variable "allow_billing_access_from_other_account_arns" {
  description = "A list of IAM ARNs from other AWS accounts that will be allowed full (read and write) access to the billing info for this account."
  type        = list(string)
  # Example:
  # default = [
  #   "arn:aws:iam::123445678910:root"
  # ]
}

variable "allow_ssh_grunt_access_from_other_account_arns" {
  description = "A list of IAM ARNs from other AWS accounts that will be allowed read access to IAM groups and publish SSH keys. This is used for ssh-grunt."
  type        = list(string)
  default     = []
  # Example:
  # default = [
  #   "arn:aws:iam::123445678910:root"
  # ]
}

variable "allow_dev_access_from_other_account_arns" {
  description = "A list of IAM ARNs from other AWS accounts that will be allowed full (read and write) access to the services in this account specified in var.dev_permitted_services."
  type        = list(string)
  # Example:
  # default = [
  #   "arn:aws:iam::123445678910:root"
  # ]
}

variable "allow_full_access_from_other_account_arns" {
  description = "A list of IAM ARNs from other AWS accounts that will be allowed full (read and write) access to this account."
  type        = list(string)
  # Example:
  # default = [
  #   "arn:aws:iam::123445678910:root"
  # ]
}

variable "allow_auto_deploy_from_other_account_arns" {
  description = "A list of IAM ARNs from other AWS accounts that will be allowed to assume the auto deploy IAM role that has the permissions in var.auto_deploy_permissions."
  type        = list(string)
  default     = []
  # Example:
  # default = [
  #   "arn:aws:iam::123445678910:role/jenkins"
  # ]
}

variable "auto_deploy_permissions" {
  description = "A list of IAM permissions (e.g. ec2:*) which will be granted for automated deployment."
  type        = list(string)
  default     = []
}

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

variable "should_require_mfa" {
  description = "Should we require that all IAM Users use Multi-Factor Authentication for both AWS API calls and the AWS Web Console? (true or false)"
  type        = bool
}

variable "iam_group_developers_permitted_services" {
  description = "A list of AWS services for which the developers IAM Group will receive full permissions. See https://goo.gl/ZyoHlz to find the IAM Service name. For example, to grant developers access only to EC2 and Amazon Machine Learning, use the value [\"ec2\",\"machinelearning\"]. Do NOT add iam to the list of services, or that will grant Developers de facto admin access. If you need to grant iam privileges, just grant the user Full Access."
  type        = list(string)
  default     = []
}

variable "iam_group_developers_s3_bucket_prefix" {
  description = "The prefix of the S3 Bucket Name to which an individual IAM User will have full access. For example, if the prefix is acme.user-, then IAM User john.doe will have access to S3 Bucket acme.user-john.doe."
  type        = string
  default     = "your-org-name.user-"
}

variable "iam_groups_for_cross_account_access" {
  description = "This variable is used to create groups that allow allow IAM users to assume roles in your other AWS accounts. It should be a list of maps, where each map has the keys group_name and iam_role_arn. For each entry in the list, we will create an IAM group that allows users to assume the given IAM role in the other AWS account. This allows you to define all your IAM users in one account (e.g. the users account) and to grant them access to certain IAM roles in other accounts (e.g. the stage, prod, audit accounts)."
  type = list(object({
    group_name   = string
    iam_role_arn = string
  }))
  default = []

  # Example:
  # default = [
  #   {
  #     group_name   = "stage-full-access"
  #     iam_role_arn = "arn:aws:iam::123445678910:role/mgmt-full-access"
  #   },
  #   {
  #     group_name   = "prod-read-only-access"
  #     iam_role_arn = "arn:aws:iam::9876543210:role/prod-read-only-access"
  #   }
  # ]
}

variable "should_create_iam_group_billing" {
  description = "Should we create the IAM Group for billing? Allows read-write access to billing features only. (true or false)"
  type        = bool
}

variable "should_create_iam_group_developers" {
  description = "Should we create the IAM Group for developers? The permissions of that group are specified via var.iam_group_developers_permitted_services. (true or false)"
  type        = bool
}

variable "should_create_iam_group_read_only" {
  description = "Should we create the IAM Group for read-only? Allows read-only access to all AWS resources. (true or false)"
  type        = bool
}

variable "iam_group_names_ssh_grunt_sudo_users" {
  description = "The list of names to be used for the IAM Group that enables its members to SSH as a sudo user into any server configured with the ssh-grunt Gruntwork module. Pass in multiple to configure multiple different IAM groups to control different groupings of access at the server level. Pass in empty list to disable creation of the IAM groups."
  type        = list(string)
}

variable "iam_group_names_ssh_grunt_users" {
  description = "The name to be used for the IAM Group that enables its members to SSH as a non-sudo user into any server configured with the ssh-grunt Gruntwork module. Pass in multiple to configure multiple different IAM groups to control different groupings of access at the server level. Pass in empty list to disable creation of the IAM groups."
  type        = list(string)
}

variable "should_create_iam_group_use_existing_iam_roles" {
  description = "Should we create the IAM Group for use-existing-iam-roles? Allow launching AWS resources with existing IAM Roles, but no ability to create new IAM Roles. (true or false)"
  type        = bool
}

variable "should_create_iam_group_auto_deploy" {
  description = "Should we create the IAM Group for auto-deploy? Allows automated deployment based on the permissions specified in var.auto_deploy_permissions. (true or false)"
  type        = bool
}

variable "cross_account_access_all_group_name" {
  description = "The name of the IAM group that will grant access to all external AWS accounts in var.iam_groups_for_cross_account_access."
  type        = string
}

variable "auto_deploy_permissions" {
  description = "A list of IAM permissions (e.g. ec2:*) that will be added to an IAM Group for doing automated deployments. NOTE: If var.should_create_iam_group_auto_deploy is true, the list must have at least one element (e.g. '*')."
  type        = list(string)
  default     = []
}

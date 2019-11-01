# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have reasonable defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
}

variable "aws_account_id" {
  description = "The ID of the AWS Account in which to create resources."
  type        = string
}

variable "minimum_password_length" {
  description = "Minimum length to require for user passwords."
  type        = number
  default     = 16
}

variable "require_numbers" {
  description = "Whether to require numbers for user passwords (true or false)."
  type        = bool
  default     = true
}

variable "require_symbols" {
  description = "Whether to require symbols for user passwords (true or false)."
  type        = bool
  default     = true
}

variable "require_lowercase_characters" {
  description = "Whether to require lowercase characters for user passwords (true or false)."
  type        = bool
  default     = true
}

variable "require_uppercase_characters" {
  description = "Whether to require uppercase characters for user passwords (true or false)."
  type        = bool
  default     = true
}

variable "allow_users_to_change_password" {
  description = "Whether to allow users to change their own password (true or false)."
  type        = bool
  default     = true
}

variable "hard_expiry" {
  description = "Whether users are prevented from setting a new password after their password has expired (i.e. require administrator reset) (true or false)."
  type        = bool
  default     = true
}

variable "max_password_age" {
  description = "The number of days that an user password is valid. Enter 0 for no expiration."
  type        = number
  default     = 0
}

variable "password_reuse_prevention" {
  description = "The number of previous passwords that users are prevented from reusing."
  type        = number
  default     = 5
}

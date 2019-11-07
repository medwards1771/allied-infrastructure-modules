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

variable "name" {
  description = "The name of the OpenVPN Server and the other resources created by these templates"
  type        = string
}

variable "instance_type" {
  description = "The type of instance to run for the OpenVPN Server"
  type        = string
}

variable "ami" {
  description = "The AMI to run on the OpenVPN Server. This should be built from the Packer template under packer/openvpn-server.json."
  type        = string
}

variable "keypair_name" {
  description = "The name of a Key Pair that can be used to SSH to this instance. Leave blank if you don't want to enable Key Pair auth."
  type        = string
}

variable "allow_ssh_from_cidr_list" {
  description = "A list of IP address ranges in CIDR format from which SSH access will be permitted. Attempts to access the OpenVPN Server from all other IP addresses will be blocked. This is only used if var.allow_ssh_from_cidr is true."
  type        = list(string)
}

variable "terraform_state_aws_region" {
  description = "The AWS region of the S3 bucket used to store Terraform remote state"
  type        = string
}

variable "terraform_state_s3_bucket" {
  description = "The name of the S3 bucket used to store Terraform remote state"
  type        = string
}

variable "current_vpc_name" {
  description = "The name of the VPC in which to deploy the OpenVPN Server"
  type        = string
}

variable "other_vpc_names" {
  description = "The name of the other VPCs you have deployed in this account. Requests for IP addresses in these VPCs will be routed over VPN."
  type        = list(string)
}

variable "tenancy" {
  description = "The tenancy of this server. Must be one of: default, dedicated, or host."
  type        = string
  default     = "default"
}

variable "request_queue_name" {
  description = "The name of the sqs queue that will be used to receive new certificate requests. Note that the queue name will be automatically prefixed with 'openvpn-requests-'."
  type        = string
}

variable "revocation_queue_name" {
  description = "The name of the sqs queue that will be used to receive certification revocation requests. Note that the queue name will be automatically prefixed with 'openvpn-requests-'."
  type        = string
}

variable "backup_bucket_name" {
  description = "The name of the s3 bucket that will be used to backup PKI secrets"
  type        = string
}

variable "vpn_subnet" {
  description = "The subnet IP and mask vpn clients will be assigned addresses from. For example, 172.16.1.0 255.255.255.0. This is a non-routed network that only exists between the VPN server and the client. Therefore, it should NOT overlap with VPC addressing, or the client won't be able to access any of the VPC IPs. In general, we recommend using internal, non-RFC 1918 IP addresses, such as 172.16.xx.yy."
  type        = string
}

variable "ca_country" {
  description = "The two-letter country code where your organization is located for the Certificate Authority"
  type        = string
}

variable "ca_state" {
  description = "The state or province name where your organization is located for the Certificate Authority"
  type        = string
}

variable "ca_locality" {
  description = "The locality name (e.g. city or town name) where your organization is located for the Certificate Authority"
  type        = string
}

variable "ca_org" {
  description = "The name of your organization (e.g. Gruntwork) for the Certificate Authority"
  type        = string
}

variable "ca_org_unit" {
  description = "The name of the unit, department, or scope within your organization for the Certificate Authority"
  type        = string
}

variable "ca_email" {
  description = "The e-mail address of the administrator for the Certificate Authority"
  type        = string
}

variable "create_route53_entry" {
  description = "Set to true to add var.domain_name as a Route 53 DNS A record for the OpenVPN server"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "The domain name to use for the OpenVPN server. Only used if var.create_route53_entry is true."
  type        = string
  default     = null
}

variable "external_account_ssh_grunt_role_arn" {
  description = "Since our IAM users are defined in a separate AWS account, this variable is used to specify the ARN of an IAM role that allows ssh-grunt to retrieve IAM group and public SSH key info from that account."
  type        = string
}

variable "external_account_arns" {
  description = "The ARNs of external AWS accounts where your IAM users are defined. This module will create IAM roles that users in those accounts will be able to assume to get access to the request/revocation SQS queues."
  type        = list(string)
}

variable "force_destroy" {
  description = "When a terraform destroy is run, should the backup s3 bucket be destroyed even if it contains files. Should only be set to true for testing/development"
  type        = bool
  default     = false
}

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

variable "cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "cluster_min_size" {
  description = "The minimum number of instances to run in the ECS cluster"
  type        = number
}

variable "cluster_max_size" {
  description = "The maxiumum number of instances to run in the ECS cluster"
  type        = number
}

variable "cluster_instance_type" {
  description = "The type of instances to run in the ECS cluster (e.g. t2.medium)"
  type        = string
}

variable "cluster_instance_ami" {
  description = "The AMI to run on each instance in the ECS cluster. You can build the AMI using the Packer template under packer/build.json."
  type        = string
}

variable "cluster_instance_keypair_name" {
  description = "The name of the Key Pair that can be used to SSH to each instance in the ECS cluster"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC in which to run the ECS cluster (e.g. stage, prod)"
  type        = string
}

variable "terraform_state_aws_region" {
  description = "The AWS region of the S3 bucket used to store Terraform remote state"
  type        = string
}

variable "terraform_state_s3_bucket" {
  description = "The name of the S3 bucket used to store Terraform remote state"
  type        = string
}

variable "allow_requests_from_public_alb" {
  description = "Set to true to allow inbound requests to this ECS cluster from the public ALB (if you're using one)"
  type        = bool
  default     = false
}

variable "allow_requests_from_internal_alb" {
  description = "Set to true to allow inbound requests to this ECS cluster from the internal ALB (if you're using one)"
  type        = bool
  default     = false
}

variable "tenancy" {
  description = "The tenancy of this server. Must be one of: default, dedicated, or host."
  type        = string
  default     = "default"
}

variable "allow_ssh" {
  description = "Set to true to allow SSH access to this ECS cluster from the OpenVPN server."
  type        = bool
  default     = true
}

variable "external_account_ssh_grunt_role_arn" {
  description = "Since our IAM users are defined in a separate AWS account, this variable is used to specify the ARN of an IAM role that allows ssh-grunt to retrieve IAM group and public SSH key info from that account."
  type        = string
}

variable "high_cpu_utilization_threshold" {
  description = "Trigger an alarm if the ECS Cluster has a CPU utilization percentage above this threshold"
  type        = number
}

variable "high_cpu_utilization_period" {
  description = "The period, in seconds, over which to measure the CPU utilization percentage"
  type        = number
}

variable "high_memory_utilization_threshold" {
  description = "Trigger an alarm if the ECS Cluster has a memory utilization percentage above this threshold"
  type        = number
}

variable "high_memory_utilization_period" {
  description = "The period, in seconds, over which to measure the memory utilization percentage"
  type        = number
}

variable "high_disk_utilization_threshold" {
  description = "Trigger an alarm if the EC2 instances in the ECS Cluster have a disk utilization percentage above this threshold"
  type        = number
}

variable "high_disk_utilization_period" {
  description = "The period, in seconds, over which to measure the disk utilization percentage"
  type        = number
}

variable "terraform_state_kms_master_key" {
  description = "Path base name of the kms master key to use. This should reflect what you have in your infrastructure-live folder."
  type = string
  default = "kms-master-key"
}

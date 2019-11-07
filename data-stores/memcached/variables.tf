# ----------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# ----------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
}

variable "aws_account_id" {
  description = "The ID of the AWS Account in which to create resources."
  type        = string
}

variable "name" {
  description = "The name used to namespace all resources created by these templates, including the ElastiCache cluster itself. Must be unique in this region. Must be a lowercase string."
  type        = string
}

# For a list of instance types, see https://aws.amazon.com/elasticache/details/#Available_Cache_Node_Types
# Note, snapshotting functionality is not compatible with t2 instance types.
variable "instance_type" {
  description = "The compute and memory capacity of the nodes (e.g. cache.m3.medium)."
  type        = string
}

variable "num_cache_nodes" {
  description = "The initial number of cache nodes that the cache cluster will have. Must be between 1 and 20."
  type        = number
}

variable "az_mode" {
  description = "Specifies whether the nodes in this Memcached node group are created in a single Availability Zone or created across multiple Availability Zones in the cluster's region. Valid values for this parameter are single-az or cross-az. If you want to choose cross-az, num_cache_nodes must be greater than 1."
  type        = string
}

variable "apply_immediately" {
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window."
  type        = bool
}

# For a list of versions, see: https://docs.aws.amazon.com/AmazonElastiCache/latest/UserGuide/SelectEngine.html
variable "memcached_version" {
  description = "Version number of memcached to use (e.g. 1.4.34)."
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

variable "vpc_name" {
  description = "The name of the VPC to deploy into"
  type        = string
}

# ----------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# ----------------------------------------------------------------------------------------------------------------------

variable "port" {
  description = "The port number on which each of the cache nodes will accept connections (e.g. 11211)."
  type        = number
  default     = 11211
}

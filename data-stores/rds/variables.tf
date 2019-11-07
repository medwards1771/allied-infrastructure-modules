# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module
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
  description = "The name used to namespace all the RDS resources created by these templates, including the cluster and cluster instances (e.g. mysql-stage). Must be unique in this region. Must be a lowercase string."
  type        = string
}

variable "port" {
  description = "The port the DB will listen on (e.g. 3306)"
  type        = number
}

variable "engine" {
  description = "The DB engine to use (e.g. mysql)"
  type        = string
}

variable "engine_version" {
  description = "The version of var.engine to use (e.g. 5.7.11 for mysql)"
  type        = string
}

variable "allocated_storage" {
  description = "The amount of storage space the DB should use, in GB."
  type        = number
}

variable "instance_type" {
  description = "The instance type to use for the db (e.g. db.t2.micro)"
  type        = string
}

variable "master_username" {
  description = "The username for the master user."
  type        = string
}

variable "master_password" {
  description = "The password for the master user."
  type        = string
}

variable "backup_retention_period" {
  description = "How many days to keep backup snapshots around before cleaning them up. Must be 1 or greater to support read replicas."
  type        = number
}

variable "apply_immediately" {
  description = "Specifies whether any cluster modifications are applied immediately, or during the next maintenance window. Note that cluster modifications may cause degraded performance or downtime."
  type        = bool
}

variable "multi_az" {
  description = "Specifies if a standby instance should be deployed in another availability zone. If the primary fails, this instance will automatically take over."
  type        = bool
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
  description = "The name of the VPC to deploy int"
  type        = string
}

variable "too_many_db_connections_threshold" {
  description = "Trigger an alarm if the number of connections to the DB instance goes above this threshold"
  type        = number
}

variable "high_cpu_utilization_threshold" {
  description = "Trigger an alarm if the DB instance has a CPU utilization percentage above this threshold"
  type        = number
}

variable "high_cpu_utilization_period" {
  description = "The period, in seconds, over which to measure the CPU utilization percentage"
  type        = number
}

variable "low_memory_available_threshold" {
  description = "Trigger an alarm if the amount of free memory, in Bytes, on the DB instance drops below this threshold"
  type        = number
}

variable "low_memory_available_period" {
  description = "The period, in seconds, over which to measure the available free memory"
  type        = number
}

variable "low_disk_space_available_threshold" {
  description = "Trigger an alarm if the amount of disk space, in Bytes, on the DB instance drops below this threshold"
  type        = number
}

variable "low_disk_space_available_period" {
  description = "The period, in seconds, over which to measure the available free disk space"
  type        = number
}

variable "enable_perf_alarms" {
  description = "Set to true to enable alarms related to performance, such as read and write latency alarms. Set to false to disable those alarms if you aren't sure what would be reasonable perf numbers for your RDS set up or if those numbers are too unpredictable."
  type        = bool
}

variable "allow_connections_from_openvpn_server" {
  description = "Allow connections from the OpenVPN Server. This can be enabled so developers can connect to the DB from their local computers. Generally, this is not recommended in prod."
  type        = bool
}

# ---------------------------------------------------------------------------------------------------------------------
# DEFINE CONSTANTS
# Generally, these values won't need to be changed.
# ---------------------------------------------------------------------------------------------------------------------

variable "db_name" {
  description = "The name for your database of up to 8 alpha-numeric characters. If you do not provide a name, Amazon RDS will not create a database in the DB cluster you are creating."
  type        = string
  default     = null
}

variable "num_read_replicas" {
  description = "The number of read replicas to deploy"
  type        = number
  default     = 0
}

# Note: you cannot enable encryption on an existing DB, so you have to enable it for the very first deployment. If you
# already created the DB unencrypted, you'll have to create a new one with encryption enabled and migrate your data to
# it. For more info on RDS encryption, see: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.Encryption.html
variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted."
  type        = bool
  default     = false
}

variable "license_model" {
  description = "The license model to use for this DB. Check the docs for your RDS DB for available license models. Set to an empty string to use the default."
  type        = string
  default     = null
}

variable "terraform_state_kms_master_key" {
  description = "Path base name of the kms master key to use. This should reflect what you have in your infrastructure-live folder."
  type = string
  default = "kms-master-key"
}

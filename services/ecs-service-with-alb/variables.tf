#---------------------------------------------------------------------------------------------------------------------
# REQUIRED MODULE PARAMETERS
# These variables must be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_account_id" {
  description = "The ID of the AWS Account in which to create resources."
  type        = string
}

variable "aws_region" {
  description = "The AWS region in which the ECS Service will be created."
  type        = string
}

variable "service_name" {
  description = "The name of the ECS service (e.g. my-service-stage)"
  type        = string
}

# Docker image configuration

variable "image" {
  description = "The Docker image to run (e.g. gruntwork/frontend-service)"
  type        = string
}

variable "image_version" {
  description = "Which version (AKA tag) of the var.image Docker image to deploy (e.g. 0.57)"
  type        = string
}

variable "container_port" {
  description = "The port number on which this service's Docker container accepts incoming HTTP or HTTPS traffic."
  type        = number
}

# Runtime properties of this ECS Service in the ECS Cluster

variable "cpu" {
  description = "The number of CPU units to allocate to the ECS Service."
  type        = number
}

variable "memory" {
  description = "How much memory, in MB, to give the ECS Service."
  type        = number
}

variable "desired_number_of_tasks" {
  description = "How many instances of the ECS Service to run across the ECS cluster"
  type        = number
}

# VPC information

variable "vpc_name" {
  description = "The name of the environment in which all the resources should be deployed (e.g. stage, prod). This is typically the name of the VPC."
  type        = string
}

variable "vpc_env_var_name" {
  description = "The name of the environment variable to pass to the ECS Task that will contain the name of the current VPC (e.g. RACK_ENV, VPC_NAME)"
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

# ALB information

variable "alb_listener_rule_configs" {
  description = "A list of all ALB Listener Rules that should be attached to an existing ALB Listener. These rules configure the ALB to send requests that come in on certain ports and paths to this ECS service. Each item in the list should be a map with the keys port (the port to match), path (the path to match), and priority (earlier priorities are matched first)."
  type = list(object({
    port = number
    path = string
    priority = number
  }))

  # Example:
  # default = [
  #   {
  #     port     = 80
  #     path     = "/foo/*"
  #     priority = 100
  #   },
  #   {
  #     port     = 443
  #     path     = "/foo/*"
  #     priority = 100
  #   }
  # ]
}

variable "health_check_path" {
  description = "The ping path that is the destination on the Targets for health checks."
  type        = string
}

variable "use_alb_sticky_sessions" {
  description = "If true, the ALB will use use Sticky Sessions as described at https://goo.gl/VLcNbk."
  type        = bool
  default     = false
}

# Alerts

variable "high_cpu_utilization_threshold" {
  description = "Trigger an alarm if the ECS Service has a CPU utilization percentage above this threshold"
  type        = number
}

variable "high_cpu_utilization_period" {
  description = "The period, in seconds, over which to measure the CPU utilization percentage"
  type        = number
}

variable "high_memory_utilization_threshold" {
  description = "Trigger an alarm if the ECS Service has a memory utilization percentage above this threshold"
  type        = number
}

variable "high_memory_utilization_period" {
  description = "The period, in seconds, over which to measure the memory utilization percentage"
  type        = number
}


# Route 53 / DNS Info

variable "create_route53_entry" {
  description = "Set to true to create a Route 53 entry for this service"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "The domain name for the DNS A record to add for this service (e.g. service.foo.com). Only used if var.create_route53_entry is true."
  type        = string
  default     = null
}

variable "enable_route53_health_check" {
  description = "If set to true, use Route 53 to perform health checks on var.domain_name."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "health_check_grace_period_seconds" {
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 1800. Only valid for services configured to use load balancers."
  type        = number
  default     = 15
}

# ALB options

variable "is_internal_alb" {
  description = "If set to true, create only private DNS entries. We should be able to compute this from the ALB automatically, but can't, due to a Terraform limitation (https://goo.gl/gq5Qyk). Only used if var.create_route53_entry is true."
  type       = bool
  default    = false
}

variable "alb_target_group_protocol" {
  description = "The network protocol to use for routing traffic from the ALB to the Targets. Must be one of HTTP or HTTPS. Note that if HTTPS is used, per https://goo.gl/NiOVx7, the ALB will use the security settings from ELBSecurityPolicy2015-05."
  type        = string
  default     = "HTTP"
}

variable "alb_target_group_deregistration_delay" {
  description = "The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds."
  type        = number
  default     = 15
}

# Docker options

variable "extra_env_vars" {
  description = "A map of environment variable name to environment variable value that should be made available to the Docker container."
  type    = map(string)
  default = {}
}

# Deployment Options

variable "deployment_maximum_percent" {
  description = "The upper limit, as a percentage of var.desired_number_of_tasks, of the number of running ECS Tasks that can be running in a service during a deployment. Setting this to more than 100 means that during deployment, ECS will deploy new instances of a Task before undeploying the old ones."
  type        = number
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "The lower limit, as a percentage of var.desired_number_of_tasks, of the number of running ECS Tasks that must remain running and healthy in a service during a deployment. Setting this to less than 100 means that during deployment, ECS may undeploy old instances of a Task before deploying new ones."
  type        = number
  default     = 100
}

variable "use_auto_scaling" {
  description = "Set this variable to 'true' to tell the ECS service to ignore var.desired_number_of_tasks and instead use Auto Scaling to determine how many ECS Tasks of this service to run."
  type        = bool
  default     = false
}

variable "min_number_of_tasks" {
  description = "For auto-scaling, the smallest possible number of ECS Tasks to be running. Only used if var.use_auto_scaling is true."
  type        = number
  default     = 0
}

variable "max_number_of_tasks" {
  description = "For auto-scaling, the largest possible number of ECS Tasks to be running. Only used if var.use_auto_scaling is true."
  type        = number
  default     = 0
}

# Health check options

variable "health_check_interval" {
  description = "The approximate amount of time, in seconds, between health checks of an individual Target. Minimum value 5 seconds, Maximum value 300 seconds."
  type        = number
  default     = 30
}

variable "health_check_protocol" {
  description = "The protocol the ALB uses when performing health checks on Targets. Must be one of HTTP and HTTPS."
  type        = string
  default     = "HTTP"
}

variable "health_check_timeout" {
  description = "The amount of time, in seconds, during which no response from a Target means a failed health check. The acceptable range is 2 to 60 seconds."
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "The number of consecutive successful health checks required before considering an unhealthy Target healthy. The acceptable range is 2 to 10."
  type        = number
  default     = 5
}

variable "health_check_unhealthy_threshold" {
  description = "The number of consecutive failed health checks required before considering a target unhealthy. The acceptable range is 2 to 10."
  type        = number
  default     = 2
}

variable "health_check_matcher" {
  description = "The HTTP codes to use when checking for a successful response from a Target. You can specify multiple values (e.g. '200,202') or a range of values (e.g. '200-299')."
  type        = string
  default     = "200"
}

variable "aws_region_env_var_name" {
  description = "The name of the environment variable that specifies the current AWS region."
  type        = string
  default     = "AWS_REGION"
}

variable "internal_alb_env_var_name" {
  description = "The name of the environment variable that specifies the URL of the internal ALB used for service-to-service communication."
  type        = string
  default     = "BACKEND_URL"
}

variable "internal_alb_port_env_var_name" {
  description = "The name of the environment variable that specifies the port of the internal ALB used for service-to-service communication."
  type        = string
  default     = "BACKEND_PORT"
}

variable "internal_alb_port" {
  description = "The port to use on the internal ALB for service-to-service communication."
  type        = number
}

# DB options

variable "db_remote_state_path" {
  description = "The path to the DB's remote state. This path does not need to include the region or VPC name. Example: data-stores/rds/terraform.tfstate."
  type        = string
  default     = "data-stores/rds/terraform.tfstate"
}

variable "db_url_env_var_name" {
  description = "The name of the env var which will contain the DB's URL."
  type        = string
  default     = "DB_URL"
}

# Memcached options

variable "memcached_remote_state_path" {
  description = "The path to Memcached remote state. This path does not need to include the region or VPC name. Example: data-stores/memcached/terraform.tfstate."
  type        = string
  default     = "data-stores/memcached/terraform.tfstate"
}

variable "memcached_url_env_var_name" {
  description = "The name of the env var which will contain the Memcached URL."
  type        = string
  default     = "MEMCACHED_URL"
}

variable "terraform_state_kms_master_key" {
  description = "Path base name of the kms master key to use. This should reflect what you have in your infrastructure-live folder."
  type = string
  default = "kms-master-key"
}

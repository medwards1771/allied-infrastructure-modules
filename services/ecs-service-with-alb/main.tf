# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY AN ECS SERVICE WITH AN APPLICATION LOAD BALANCER IN FRONT OF IT
# These templates deploy an ECS Service meant to be fronted by an Application Load Balancer.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  # The AWS region in which all resources will be created
  region = var.aws_region

  # Provider version 2.X series is the latest, but has breaking changes with 1.X series.
  version = "~> 2.6"

  # Only these AWS Account IDs may be operated on by this template
  allowed_account_ids = [var.aws_account_id]
}

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE REMOTE STATE STORAGE
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}

  # Only allow this Terraform version. Note that if you upgrade to a newer version, Terraform won't allow you to use an
  # older version, so when you upgrade, you should upgrade everyone on your team and your CI servers all at once.
  required_version = "= 0.12.9"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN ECS SERVICE TO RUN THE ECS TASK
# ---------------------------------------------------------------------------------------------------------------------

module "ecs_service" {
  source = "git::git@github.com:gruntwork-io/module-ecs.git//modules/ecs-service?ref=v0.16.0"

  service_name = var.service_name
  environment_name = var.vpc_name

  ecs_cluster_arn                = data.terraform_remote_state.ecs_cluster.outputs.ecs_cluster_arn
  ecs_task_container_definitions = data.template_file.ecs_task_container_definitions.rendered

  desired_number_of_tasks = var.desired_number_of_tasks
  min_number_of_tasks     = var.use_auto_scaling ? var.min_number_of_tasks : null
  max_number_of_tasks     = var.use_auto_scaling ? var.max_number_of_tasks : null

  # ALB configuration
  dependencies = [data.terraform_remote_state.alb.outputs.alb_arn]
  is_associated_with_elb = true
  elb_target_group_name = ""
  elb_target_group_vpc_id           = data.terraform_remote_state.vpc.outputs.vpc_id
  elb_container_name      = var.service_name
  elb_container_port      = var.container_port
  use_alb_sticky_sessions = var.use_alb_sticky_sessions

  elb_target_group_protocol             = var.alb_target_group_protocol
  elb_target_group_deregistration_delay = var.alb_target_group_deregistration_delay
  health_check_grace_period_seconds     = var.health_check_grace_period_seconds

  # Deployment options
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  use_auto_scaling                   = var.use_auto_scaling

  # Health check configuration
  health_check_path                = var.health_check_path
  health_check_interval            = var.health_check_interval
  health_check_protocol            = var.health_check_protocol
  health_check_timeout             = var.health_check_timeout
  health_check_healthy_threshold   = var.health_check_healthy_threshold
  health_check_unhealthy_threshold = var.health_check_unhealthy_threshold
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN ECS TASK TO RUN THE DOCKER CONTAINER
# ---------------------------------------------------------------------------------------------------------------------

# This template_file defines the Docker containers we want to run in our ECS Task
data "template_file" "ecs_task_container_definitions" {
  template = file("${path.module}/container-definition/container-definition.json")

  vars = {
    container_name = var.service_name

    image = var.image
    version = var.image_version
    cpu = var.cpu
    memory = var.memory
    port_mappings = "[${join(",", data.template_file.port_mappings.*.rendered)}]"
    env_vars = "[${join(",",  data.template_file.all_env_vars.*.rendered)}]"
  }
}

# Convert the maps of ports to the container definition JSON format.
data "template_file" "port_mappings" {
  template = <<EOF
  {
    "containerPort": ${var.container_port},
    "protocol": "tcp"
  }
  EOF
}

locals {
  # Create default map of env vars in the JSON format used by ECS container definitions.
  default_env_vars = map(
    var.vpc_env_var_name, var.vpc_name,
    var.aws_region_env_var_name, var.aws_region,
    var.db_url_env_var_name, data.terraform_remote_state.db.outputs.primary_endpoint,
    var.memcached_url_env_var_name, join(",", data.terraform_remote_state.memcached.outputs.cache_addresses),
    var.internal_alb_env_var_name, data.terraform_remote_state.alb_internal.outputs.alb_dns_name,
    var.internal_alb_port_env_var_name, var.internal_alb_port,
  )

  # Merge the default env vars with any extra env vars passed in by the user into a single map
  all_env_vars = merge(local.default_env_vars, var.extra_env_vars)
}

# Convert the env vars into a JSON format used by ECS container definitions.
data "template_file" "all_env_vars" {
  count = length(local.all_env_vars)
  template = <<EOF
{
  "name": "${element(keys(local.all_env_vars), count.index)}",
  "value": "${lookup(local.all_env_vars, element(keys(local.all_env_vars), count.index))}"
}
EOF
}

# Give this ECS Service access to the KMS Master Key so it can use it to decrypt secrets in config files.
resource "aws_iam_role_policy" "access_kms_master_key" {
  name = "access-kms-master-key"
  role = module.ecs_service.ecs_task_iam_role_name
  policy = data.aws_iam_policy_document.access_kms_master_key.json
}

# Create an IAM Policy for acessing the KMS Master Key
data "aws_iam_policy_document" "access_kms_master_key" {
  statement {
    effect = "Allow"
    actions = ["kms:Decrypt"]
    resources = [data.terraform_remote_state.kms_master_key.outputs.key_arn]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE THE ROUTING RULES FOR THIS SERVICE
# Below, we configure the ALB to send requests that come in on certain ports (the listener_arn) and certain paths or
# domain names (the condition block) to the Target Group that contains this ECS service.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_alb_listener_rule" "paths_to_route_to_this_service" {
  count = length(var.alb_listener_rule_configs)
  listener_arn = lookup(data.terraform_remote_state.alb.outputs.listener_arns, lookup(var.alb_listener_rule_configs[count.index], "port"))
  priority     = lookup(var.alb_listener_rule_configs[count.index], "priority")

  action {
    type             = "forward"
    target_group_arn = module.ecs_service.target_group_arn
  }

  condition {
    field  = "path-pattern"
    values = [var.alb_listener_rule_configs[count.index]["path"]]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A DNS RECORD USING ROUTE 53
# ---------------------------------------------------------------------------------------------------------------------

# The ECS Service's endpoint will point to the ELB.
resource "aws_route53_record" "dns_record" {
  count = var.create_route53_entry ? 1 : 0

  zone_id = element(
    concat(
      data.terraform_remote_state.route53_private.*.outputs.internal_services_hosted_zone_id,
      data.terraform_remote_state.route53_public.*.outputs.primary_domain_hosted_zone_id,
    ),
    0,
  )
  name = var.domain_name
  type = "A"

  alias {
    name = data.terraform_remote_state.alb.outputs.original_alb_dns_name
    zone_id = data.terraform_remote_state.alb.outputs.alb_hosted_zone_id
    evaluate_target_health = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ADD A ROUTE 53 HEALTHCHECK THAT TRIGGERS AN ALARM IF THE DOMAIN NAME IS UNRESPONSIVE
# Note: Route 53 sends all of its CloudWatch metrics to us-east-1, so the health check, alarm, and SNS topic must ALL
# live in us-east-1 as well! See https://github.com/hashicorp/terraform/issues/7371 for details.
# ---------------------------------------------------------------------------------------------------------------------

module "route53_health_check" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/alarms/route53-health-check-alarms?ref=v0.13.2"
  domain = var.domain_name == null ? data.terraform_remote_state.alb.outputs.alb_dns_name : var.domain_name
  alarm_sns_topic_arns_us_east_1 = [data.terraform_remote_state.sns_us_east_1.outputs.arn]

  path = var.health_check_path
  type = var.health_check_protocol
  port = var.health_check_protocol == "HTTP" ? 80 : 443

  failure_threshold = 2
  request_interval = 30

  enabled = var.enable_route53_health_check
}

# ---------------------------------------------------------------------------------------------------------------------
# ADD CLOUDWATCH ALARMS FOR THIS ECS SERVICE
# ---------------------------------------------------------------------------------------------------------------------

# Add CloudWatch Alarms that go off if the ECS Service's CPU or Memory usage gets too high.
module "ecs_service_cpu_memory_alarms" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/alarms/ecs-service-alarms?ref=v0.13.2"
  ecs_service_name = var.service_name
  ecs_cluster_name = data.terraform_remote_state.ecs_cluster.outputs.ecs_cluster_name
  alarm_sns_topic_arns = [data.terraform_remote_state.sns_region.outputs.arn]

  high_cpu_utilization_threshold = var.high_cpu_utilization_threshold
  high_cpu_utilization_period = var.high_cpu_utilization_period
  high_memory_utilization_threshold = var.high_memory_utilization_threshold
  high_memory_utilization_period = var.high_memory_utilization_period
}

# Create a set of CloudWatch Alarms on the Target Group associated with the ECS Service
module "target_group_cloudwatch_alarms" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/alarms/alb-target-group-alarms?ref=v0.13.2"

  alb_arn = data.terraform_remote_state.alb.outputs.alb_arn
  alb_name = data.terraform_remote_state.alb.outputs.alb_name
  target_group_name = module.ecs_service.target_group_name
  target_group_arn = module.ecs_service.target_group_arn
  alarm_sns_topic_arns = [data.terraform_remote_state.sns_region.outputs.arn]
}

module "metric_widget_ecs_service_cpu_usage" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/metrics/cloudwatch-dashboard-metric-widget?ref=v0.13.2"

  period = 60
  stat   = "Average"
  title  = "${title(var.service_name)} CPUUtilization"

  metrics = [
    ["AWS/ECS", "CPUUtilization", "ClusterName", data.terraform_remote_state.ecs_cluster.outputs.ecs_cluster_name, "ServiceName", var.service_name],
  ]
}

module "metric_widget_ecs_service_memory_usage" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/metrics/cloudwatch-dashboard-metric-widget?ref=v0.13.2"

  period = 60
  stat   = "Average"
  title  = "${title(var.service_name)} MemoryUtilization"

  metrics = [
    ["AWS/ECS", "MemoryUtilization", "ClusterName", data.terraform_remote_state.ecs_cluster.outputs.ecs_cluster_name, "ServiceName", var.service_name],
  ]
}

locals {
  load_balancer_dimension_value = replace(
    element(
      split(":", data.terraform_remote_state.alb.outputs.alb_arn),
      5,
    ),
    "loadbalancer/",
    "",
  )
  target_group_dimension_value = element(split(":", module.ecs_service.target_group_arn), 5)
}

module "metric_widget_target_group_host_count" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/metrics/cloudwatch-dashboard-metric-widget?ref=v0.13.2"

  period = 60
  stat   = "Average"
  title  = "${title(data.terraform_remote_state.alb.outputs.alb_name)} HealthyHostCount"

  metrics = [
    ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", local.load_balancer_dimension_value, "TargetGroup", local.target_group_dimension_value],
  ]
}

module "metric_widget_target_group_request_count" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/metrics/cloudwatch-dashboard-metric-widget?ref=v0.13.2"

  period = 60
  stat   = "Average"
  title  = "${title(data.terraform_remote_state.alb.outputs.alb_name)} RequestCount"

  metrics = [
    ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.load_balancer_dimension_value, "TargetGroup", local.target_group_dimension_value],
  ]
}

module "metric_widget_target_group_connection_error_count" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/metrics/cloudwatch-dashboard-metric-widget?ref=v0.13.2"

  period = 60
  stat   = "Average"
  title  = "${title(data.terraform_remote_state.alb.outputs.alb_name)} TargetConnectionErrorCount"

  metrics = [
    ["AWS/ApplicationELB", "TargetConnectionErrorCount", "LoadBalancer", local.load_balancer_dimension_value, "TargetGroup", local.target_group_dimension_value],
  ]
}

module "metric_widget_target_group_response_time" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/metrics/cloudwatch-dashboard-metric-widget?ref=v0.13.2"

  period = 60
  stat   = "Average"
  title  = "${title(data.terraform_remote_state.alb.outputs.alb_name)} TargetResponseTime"

  metrics = [
    ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.load_balancer_dimension_value, "TargetGroup", local.target_group_dimension_value],
  ]
}

module "metric_widget_target_group_4xx_count" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/metrics/cloudwatch-dashboard-metric-widget?ref=v0.13.2"

  period = 60
  stat   = "Average"
  title  = "${title(data.terraform_remote_state.alb.outputs.alb_name)} HTTPCode_Target_4XX_Count"

  metrics = [
    ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", local.load_balancer_dimension_value, "TargetGroup", local.target_group_dimension_value],
  ]
}

module "metric_widget_target_group_5xx_count" {
  source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/metrics/cloudwatch-dashboard-metric-widget?ref=v0.13.2"

  period = 60
  stat   = "Average"
  title  = "${title(data.terraform_remote_state.alb.outputs.alb_name)} HTTPCode_Target_5XX_Count"

  metrics = [
    ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.load_balancer_dimension_value, "TargetGroup", local.target_group_dimension_value],
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# PULL DATA FROM OTHER TERRAFORM TEMPLATES USING TERRAFORM REMOTE STATE
# These templates use Terraform remote state to access data from a number of other Terraform templates, all of which
# store their state in S3 buckets.
# ---------------------------------------------------------------------------------------------------------------------

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/${var.vpc_name}/vpc/terraform.tfstate"
  }
}

data "terraform_remote_state" "ecs_cluster" {
  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/${var.vpc_name}/services/ecs-cluster/terraform.tfstate"
  }
}

data "terraform_remote_state" "alb" {
  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/${var.vpc_name}/networking/${var.is_internal_alb ? "alb-internal" : "alb-public"}/terraform.tfstate"
  }
}

data "terraform_remote_state" "alb_internal" {
  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/${var.vpc_name}/networking/alb-internal/terraform.tfstate"
  }
}

data "terraform_remote_state" "sns_region" {
  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/_global/sns-topics/terraform.tfstate"
  }
}

# Route 53 health check alarms can only go to the us-east-1 region
data "terraform_remote_state" "sns_us_east_1" {
  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "us-east-1/_global/sns-topics/terraform.tfstate"
  }
}

data "terraform_remote_state" "kms_master_key" {
  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/_global/${var.terraform_state_kms_master_key}/terraform.tfstate"
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/${var.vpc_name}/${var.db_remote_state_path}"
  }
}

data "terraform_remote_state" "memcached" {
  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/${var.vpc_name}/${var.memcached_remote_state_path}"
  }
}


data "terraform_remote_state" "route53_private" {
  count = var.create_route53_entry && var.is_internal_alb ? 1 : 0

  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "${var.aws_region}/${var.vpc_name}/networking/route53-private/terraform.tfstate"
  }
}

data "terraform_remote_state" "route53_public" {
  count = var.create_route53_entry && (! var.is_internal_alb) ? 1 : 0

  backend = "s3"
  config = {
    region = var.terraform_state_aws_region
    bucket = var.terraform_state_s3_bucket
    key    = "_global/route53-public/terraform.tfstate"
  }
}

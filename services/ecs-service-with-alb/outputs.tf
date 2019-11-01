output "ecs_service_arn" {
  value = module.ecs_service.service_arn
}

output "ecs_task_iam_role_name" {
  value = module.ecs_service.ecs_task_iam_role_name
}

output "ecs_task_iam_role_arn" {
  value = module.ecs_service.ecs_task_iam_role_arn
}

output "aws_ecs_task_definition_arn" {
  value = module.ecs_service.aws_ecs_task_definition_arn
}

output "target_group_name" {
  value = module.ecs_service.target_group_name
}

output "target_group_arn" {
  value = module.ecs_service.target_group_arn
}

output "fully_qualified_domain_name" {
  value = var.create_route53_entry ? var.domain_name : data.terraform_remote_state.alb.outputs.alb_dns_name
}

output "metric_widget_ecs_service_cpu_usage" {
  value = module.metric_widget_ecs_service_cpu_usage.widget
}

output "metric_widget_ecs_service_memory_usage" {
  value = module.metric_widget_ecs_service_memory_usage.widget
}

output "metric_widget_target_group_host_count" {
  value = module.metric_widget_target_group_host_count.widget
}

output "metric_widget_target_group_request_count" {
  value = module.metric_widget_target_group_request_count.widget
}

output "metric_widget_target_group_connection_error_count" {
  value = module.metric_widget_target_group_connection_error_count.widget
}

output "metric_widget_target_group_response_time" {
  value = module.metric_widget_target_group_response_time.widget
}

output "metric_widget_target_group_4xx_count" {
  value = module.metric_widget_target_group_4xx_count.widget
}

output "metric_widget_target_group_5xx_count" {
  value = module.metric_widget_target_group_5xx_count.widget
}
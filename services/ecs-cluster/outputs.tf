output "aws_region" {
  value = var.aws_region
}

output "ecs_cluster_arn" {
  value = module.ecs_cluster.ecs_cluster_arn
}

output "ecs_cluster_name" {
  value = module.ecs_cluster.ecs_cluster_name
}

output "ecs_cluster_asg_name" {
  value = module.ecs_cluster.ecs_cluster_asg_name
}

output "ecs_instance_security_group_id" {
  value = module.ecs_cluster.ecs_instance_security_group_id
}

output "ecs_instance_iam_role_arn" {
  value = module.ecs_cluster.ecs_instance_iam_role_arn
}

output "asg_name" {
  value = module.ecs_cluster.ecs_cluster_asg_name
}

output "metric_widget_ecs_cluster_cpu_usage" {
  value = module.metric_widget_ecs_cluster_cpu_usage.widget
}

output "metric_widget_ecs_cluster_memory_usage" {
  value = module.metric_widget_ecs_cluster_memory_usage.widget
}

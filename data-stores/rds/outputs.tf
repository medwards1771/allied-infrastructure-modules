output "primary_id" {
  value = module.database.primary_id
}

output "primary_arn" {
  value = module.database.primary_arn
}

output "primary_endpoint" {
  value = module.database.primary_endpoint
}

output "num_read_replicas" {
  value = var.num_read_replicas
}

# These will only show up if you set num_read_replicas > 0
output "read_replica_ids" {
  value = module.database.read_replica_ids
}

# These will only show up if you set num_read_replicas > 0
output "read_replica_arns" {
  value = module.database.read_replica_arns
}

# These will only show up if you set num_read_replicas > 0
output "read_replica_endpoints" {
  value = module.database.read_replica_endpoints
}

# The primary_endpoint is of the format <host>:<port>. This output returns just the host part.
output "primary_host" {
  value = element(split(":", module.database.primary_endpoint), 0)
}

output "port" {
  value = module.database.port
}

output "name" {
  value = var.name
}

output "db_name" {
  value = module.database.db_name
}

output "metric_widget_rds_cpu_usage" {
  value = module.metric_widget_rds_cpu_usage.widget
}

output "metric_widget_rds_memory" {
  value = module.metric_widget_rds_memory.widget
}

output "metric_widget_rds_disk_space" {
  value = module.metric_widget_rds_disk_space.widget
}

output "metric_widget_rds_db_connections" {
  value = module.metric_widget_rds_db_connections.widget
}

output "metric_widget_rds_read_latency" {
  value = module.metric_widget_rds_read_latency.widget
}

output "metric_widget_rds_write_latency" {
  value = module.metric_widget_rds_write_latency.widget
}

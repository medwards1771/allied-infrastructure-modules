output "name" {
  value = var.name
}

output "arn" {
  value = module.dashboard.dashboard_arn
}

output "widgets" {
  value = module.dashboard.widgets
}

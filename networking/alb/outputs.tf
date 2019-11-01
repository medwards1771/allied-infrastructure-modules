output "alb_name" {
  value = module.alb.alb_name
}

output "alb_arn" {
  value = module.alb.alb_arn
}

output "alb_dns_name" {
  value = var.create_route53_entry ? join(",", aws_route53_record.dns_record.*.fqdn) : module.alb.alb_dns_name
}

output "original_alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "alb_hosted_zone_id" {
  value = module.alb.alb_hosted_zone_id
}

output "alb_security_group_id" {
  value = module.alb.alb_security_group_id
}

output "listener_arns" {
  value = module.alb.listener_arns
}

output "http_listener_arns" {
  value = module.alb.http_listener_arns
}

output "https_listener_non_acm_cert_arns" {
  value = module.alb.https_listener_non_acm_cert_arns
}

output "https_listener_acm_cert_arns" {
  value = module.alb.https_listener_acm_cert_arns
}

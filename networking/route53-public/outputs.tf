output "primary_domain_name" {
  value = aws_route53_zone.primary_domain.name
}

output "primary_domain_hosted_zone_id" {
  value = aws_route53_zone.primary_domain.zone_id
}

output "primary_domain_hosted_zone_name_servers" {
  value = aws_route53_zone.primary_domain.name_servers
}

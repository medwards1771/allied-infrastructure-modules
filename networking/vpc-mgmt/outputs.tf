output "vpc_name" {
  value = module.vpc.vpc_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  value = module.vpc.vpc_cidr_block
}

output "public_subnet_cidr_blocks" {
  value = module.vpc.public_subnet_cidr_blocks
}

output "private_subnet_cidr_blocks" {
  value = module.vpc.private_subnet_cidr_blocks
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "public_subnet_route_table_id" {
  value = module.vpc.public_subnet_route_table_id
}

output "private_subnet_route_table_ids" {
  value = module.vpc.private_subnet_route_table_ids
}

output "nat_gateway_public_ips" {
  value = module.vpc.nat_gateway_public_ips
}

output "num_availability_zones" {
  value = module.vpc.num_availability_zones
}

output "availability_zones" {
  value = module.vpc.availability_zones
}

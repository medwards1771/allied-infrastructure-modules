output "key_arn" {
  value = module.kms_master_key.key_arn
}

output "key_id" {
  value = module.kms_master_key.key_id
}

output "key_alias" {
  value = module.kms_master_key.key_alias
}

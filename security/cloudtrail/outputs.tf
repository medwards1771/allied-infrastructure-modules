output "trail_arn" {
  value = module.cloudtrail.trail_arn
}

output "s3_bucket_name" {
  value = module.cloudtrail.s3_bucket_name
}

output "kms_key_arn" {
  value = module.cloudtrail.kms_key_arn
}

output "kms_key_alias_name" {
  value = module.cloudtrail.kms_key_alias_name
}

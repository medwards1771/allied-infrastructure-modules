output "billing_iam_group_name" {
  value = module.iam_groups.billing_iam_group_name
}

output "billing_iam_group_arn" {
  value = module.iam_groups.billing_iam_group_arn
}

output "developers_iam_group_name" {
  value = module.iam_groups.developers_iam_group_name
}

output "developers_iam_group_arn" {
  value = module.iam_groups.developers_iam_group_arn
}

output "full_access_iam_group_name" {
  value = module.iam_groups.full_access_iam_group_name
}

output "full_access_iam_group_arn" {
  value = module.iam_groups.full_access_iam_group_arn
}

output "read_only_iam_group_name" {
  value = module.iam_groups.read_only_iam_group_name
}

output "read_only_iam_group_arn" {
  value = module.iam_groups.read_only_iam_group_arn
}

output "use_existing_iam_roles_iam_group_name" {
  value = module.iam_groups.use_existing_iam_roles_iam_group_name
}

output "use_existing_iam_roles_iam_group_arn" {
  value = module.iam_groups.use_existing_iam_roles_iam_group_arn
}

output "iam_self_mgmt_iam_policy_arn" {
  value = module.iam_groups.iam_self_mgmt_iam_policy_arn
}

output "cross_account_access_group_arns" {
  value = module.iam_groups.cross_account_access_group_arns
}

output "cross_account_access_all_group_arn" {
  value = module.iam_groups.cross_account_access_all_group_arn
}

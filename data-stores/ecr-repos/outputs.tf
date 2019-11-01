output "ecr_repo_arns" {
  value = zipmap(var.repo_names, aws_ecr_repository.repos.*.arn)
}

output "ecr_repo_urls" {
  value = zipmap(var.repo_names, aws_ecr_repository.repos.*.repository_url)
}

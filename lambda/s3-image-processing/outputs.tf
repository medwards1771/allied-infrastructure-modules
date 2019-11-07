output "function_name" {
  value = module.lambda_s3.function_name
}

output "function_arn" {
  value = module.lambda_s3.function_arn
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.images.arn
}

output "s3_bucket_name" {
  value = aws_s3_bucket.images.bucket
}

output "image_filename" {
  value = aws_s3_bucket_object.gruntwork_logo.key
}

output "s3_bucket_id" {
  value = aws_s3_bucket.state.id
}

output "dynamodb_table_id" {
  value = module.dynamodb_table.dynamodb_table_id
}
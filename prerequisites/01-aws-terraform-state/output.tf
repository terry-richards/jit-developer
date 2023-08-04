output "s3_bucket_id" {
  value = module.s3_bucket.bucket_id
}

output "dynamodb_table_id" {
  value = module.dynamodb_table.table_id
}
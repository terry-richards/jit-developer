module "s3_bucket" {
  source  = "cloudposse/s3-bucket/aws"
  version = "3.1.2"

  namespace               = var.namespace
  name                    = "terraform-state"
  acl                     = "private"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning_enabled = true

}

module "dynamodb_table" {
  source    = "cloudposse/dynamodb/aws"
  version   = "0.33.0"
  namespace = var.namespace
  name      = "terraform-lock"
  hash_key  = "LockID"

  dynamodb_attributes = [
    {
      name = "LockID"
      type = "S"
    }
  ]

}

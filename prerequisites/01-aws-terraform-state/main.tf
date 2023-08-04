resource "aws_s3_bucket" "state" {
  bucket = "tmrsd-terraform-state"
}

resource "aws_s3_bucket_acl" "acl" {
  bucket = aws_s3_bucket.state.id
  acl    = "private"
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_public_access_block" "access_block" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

module "dynamodb_table" {
  source   = "terraform-aws-modules/dynamodb-table/aws"
  version  = "3.3.0"
  name     = "tmrsd-terraform-lock"
  hash_key = "LockID"

  attributes = [
    {
      name = "LockID"
      type = "S"
    }
  ]

}

# [Resource to avoid error](https://stackoverflow.com/a/76115428) "AccessControlListNotSupported: The bucket does not allow ACLs"
resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.state.id
  rule {
    object_ownership = "ObjectWriter"
  }
}
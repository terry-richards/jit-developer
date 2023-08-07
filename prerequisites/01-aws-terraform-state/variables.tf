variable "namespace" {
  type        = string
  description = "Namespace, which could be your organization name or abbreviation"
}

variable "aws_region" {
  type        = string
  description = "AWS region where the instance will be created"
}

variable "terraform_state_bucket_prefix" {
  type        = string
  description = "Prefix for the Terraform S3 bucket"
}

variable "terraform_state_lock_table" {
  type        = string
  description = "Name of the DynamoDB table where the Terraform state lock will be stored"
}

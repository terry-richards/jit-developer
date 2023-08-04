variable "namespace" {
  type        = string
  description = "Namespace, which could be your organization name or abbreviation"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "aws_region" {
  type        = string
  description = "AWS region where the instance will be created"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type. See https://aws.amazon.com/ec2/instance-types/ for a list of available types."
  default     = "m6a.large"
}

variable "developer_name" {
  type        = string
  description = "name of the developer whose public key will be used to access the instance"
}

variable "developer_email" {
  type        = string
  description = "email of the developer whose public key will be used to access the instance"
}

variable "developer_timezone" {
  type        = string
  description = "timezone of the developer whose public key will be used to access the instance"
  default     = "America/New_York"
}

variable "development_subnet_id" {
  type        = string
  description = "ID of the subnet where the instance will be created"
}

variable "development_vpc_id" {
  type        = string
  description = "ID of the VPC where the security group will be created"
}

variable "output_dir" {
  type        = string
  description = "directory where the private key will be saved"
  default = "./out"
}

variable "root_volume_size" {
  type        = number
  description = "size of the root volume in GB"
  default     = 100
}

# Derived locals
locals {
  developer_user_name = split("@", var.developer_email)[0]
}
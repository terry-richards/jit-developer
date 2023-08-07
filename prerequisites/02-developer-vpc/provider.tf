terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.10.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
  }
  backend "s3" {
    key            = "development-vpc/terraform.tfstate"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "terraform"

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Namespace = var.namespace
    }
  }
}
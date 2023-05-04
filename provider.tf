terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket = "bucketname"
    key    = "backend"
    region = "us-west-2"
  }
}

provider "aws" {
  region = "us-west-2"
  assume_role {
    role_arn     = "arn:aws:iam::xxxxxx:role/terraform-assume-role"
    session_name = "SESSION_NAME"
    external_id  = "EXTERNAL_ID"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    region = "eu-west-1"

    bucket  = "vnp-dev-tf-state"
    key     = "vnp-dev/vpn/terraform.tfstate"
    encrypt = true

    dynamodb_table = "vnp-tf-state-locks"
  }
}

provider "aws" {
  region = "eu-west-1"
}
terraform {
  required_version = ">= 1.10.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.25.0"
    }
  }
}

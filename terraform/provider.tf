terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

# Local values for common tags applied to all resources
locals {
  # Note: awsApplication tag is set after AppRegistry app is created
  # This will be populated in subsequent terraform apply
  common_tags = merge(
    {
      Project        = var.app_name
      Environment    = var.environment
      ManagedBy      = "Terraform"
      CreatedDate    = formatdate("YYYY-MM-DD", timestamp())
      Owner          = var.owner
      CostCenter     = var.cost_center
      Application    = var.app_name
    },
    var.additional_tags
  )
}

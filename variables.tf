variable "aws_region" {
  description = "AWS Region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Name prefix for resources"
  type        = string
  default     = "my-secure-app"
}



variable "aws_account_id" {
  description = "AWS Account ID for ECR"
  type        = string
}

variable "cognito_domain_prefix" {
  description = "Unique prefix for the Cognito hosted UI"
  type        = string
}

locals {
  app_frontend_image = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.app_name}-app-frontend:latest"
  backend_image      = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.app_name}-backend:latest"
}

variable "additional_callback_urls" {
  description = "Additional callback URLs for multiple environments (dev/staging/prod)"
  type        = list(string)
  default     = []
}

variable "additional_logout_urls" {
  description = "Additional logout URLs for multiple environments (dev/staging/prod)"
  type        = list(string)
  default     = []
}

variable "allow_admin_create_user_only" {
  description = "Only allow admins to create users (closed registration)"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
  default     = "production"
}

variable "owner" {
  description = "Resource owner/team"
  type        = string
  default     = "DevOps"
}

variable "cost_center" {
  description = "Cost center for billing allocation"
  type        = string
  default     = "engineering"
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

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



variable "backend_image" {
  description = "ECR URI for the backend image"
  type        = string
}

variable "cognito_domain_prefix" {
  description = "Unique prefix for the Cognito hosted UI"
  type        = string
}

variable "app_frontend_image" {
  description = "ECR URI for the app frontend image (Next.js)"
  type        = string
  default     = "884337373788.dkr.ecr.us-east-1.amazonaws.com/my-app-app-frontend:latest"
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

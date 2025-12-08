aws_region            = "us-east-1"
app_name              = "my-secure-app"
app_frontend_image    = "884337373788.dkr.ecr.us-east-1.amazonaws.com/my-app-app-frontend:latest"
backend_image         = "884337373788.dkr.ecr.us-east-1.amazonaws.com/my-app-backend:latest"
cognito_domain_prefix = "my-secure-app-auth-123" # Must be unique across AWS
environment           = "production"
owner                 = "DevOps"
cost_center           = "engineering"

# Additional tags to apply to all resources
additional_tags = {
  Compliance    = "Required"
  DataClass     = "Internal"
  BackupPolicy  = "Daily"
}

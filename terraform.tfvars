aws_region            = "us-east-1"
aws_account_id        = "884337373788"
app_name              = "my-secure-4"
cognito_domain_prefix = "my-secure-app4-auth-123" # Must be unique across AWS
allow_admin_create_user_only = true # Disable self-registration, only admins can create users
environment           = "production"
owner                 = "DevOps"
cost_center           = "engineering"

# Additional tags to apply to all resources
additional_tags = {
  Compliance    = "Required"
  DataClass     = "Internal"
  BackupPolicy  = "Daily"
}

output "alb_dns_name" {
  description = "The public DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "cognito_user_pool_id" {
  description = "The ID of the created Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_client_id" {
  description = "The App Client ID for the User Pool"
  value       = aws_cognito_user_pool_client.client.id
}

output "app_frontend_service_name" {
  description = "Name of the ECS App Frontend Service"
  value       = aws_ecs_service.app_frontend.name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "backend_service_name" {
  description = "Name of the ECS Backend Service"
  value       = aws_ecs_service.backend.name
}

output "target_group_arn" {
  description = "ARN of the app frontend target group"
  value       = aws_lb_target_group.app_frontend.arn
}

output "cognito_domain" {
  description = "Cognito hosted UI domain"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "aws_region" {
  description = "AWS region for Cognito endpoints"
  value       = var.aws_region
}

output "cognito_idp_uri" {
  description = "Cognito IDP base URI for login/logout"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com"
}

output "login_uri" {
  description = "Full Cognito login URI for testing"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com/login?client_id=${aws_cognito_user_pool_client.client.id}&response_type=code&redirect_uri=https://${aws_lb.main.dns_name}/oauth2/idpresponse"
}

output "logout_uri" {
  description = "Full Cognito logout URI for testing"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com/logout?client_id=${aws_cognito_user_pool_client.client.id}&logout_uri=https://${aws_lb.main.dns_name}/logout-success"
}

output "cognito_jwks_uri" {
  description = "Cognito JWKS endpoint for token verification"
  value       = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.main.id}/.well-known/jwks.json"
}

output "cognito_client_secret" {
  description = "Cognito client secret (sensitive)"
  value       = aws_cognito_user_pool_client.client.client_secret
  sensitive   = true
}

output "appregistry_application_id" {
  description = "AppRegistry Application ID for centralized management"
  value       = aws_servicecatalogappregistry_application.main.id
}

output "appregistry_application_arn" {
  description = "AppRegistry Application ARN"
  value       = aws_servicecatalogappregistry_application.main.arn
}

output "s3_file_uploads_bucket" {
  description = "S3 bucket for file uploads"
  value       = aws_s3_bucket.file_uploads.id
}

output "s3_bucket_region" {
  description = "AWS region for S3 bucket"
  value       = aws_s3_bucket.file_uploads.region
}


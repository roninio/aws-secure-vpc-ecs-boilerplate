# AWS Service Catalog AppRegistry - Application Definition
resource "aws_servicecatalogappregistry_application" "main" {
  name        = var.app_name
  description = "Secure web application with ECS Fargate, Cognito authentication, and ALB"
}

# Attribute Group - Application Metadata
resource "aws_servicecatalogappregistry_attribute_group" "main" {
  name        = "${var.app_name}-attributes"
  description = "Application metadata and tags"

  attributes = jsonencode({
    version     = "1.0.0"
    environment = "production"
    owner       = "platform-team"
    managedBy   = "terraform"
    repository  = "aws-terra"
  })
}

# Associate Attribute Group with Application
resource "aws_servicecatalogappregistry_attribute_group_association" "main" {
  application_id     = aws_servicecatalogappregistry_application.main.id
  attribute_group_id = aws_servicecatalogappregistry_attribute_group.main.id
}

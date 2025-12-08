resource "aws_ecr_repository" "app_frontend" {
  name                 = "my-app-app-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "app-frontend"
    Description = "ECR repository for Next.js app-frontend Docker images"
  }
}

resource "aws_ecr_repository" "backend" {
  name                 = "my-app-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "backend"
    Description = "ECR repository for FastAPI backend Docker images"
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-cluster"

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.app_name}-cluster"
      Description = "ECS Fargate cluster for containerized services"
      Type        = "Cluster"
    }
  )
}

# CloudWatch Log Groups for ECS tasks
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.app_name}-backend"
  retention_in_days = 7

  tags = {
    Name        = "${var.app_name}-backend-logs"
    Description = "CloudWatch logs for backend service"
  }
}

resource "aws_cloudwatch_log_group" "app_frontend" {
  name              = "/ecs/${var.app_name}-app-frontend"
  retention_in_days = 7

  tags = {
    Name        = "${var.app_name}-app-frontend-logs"
    Description = "CloudWatch logs for app-frontend service"
  }
}



# Backend Task Definition
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.app_name}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  tags = {
    Name        = "${var.app_name}-backend-task"
    Description = "Task definition for FastAPI backend service"
  }

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = local.backend_image
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      environment = [
        {
          name  = "TABLE_NAME"
          value = aws_dynamodb_table.main.name
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "S3_BUCKET_NAME"
          value = aws_s3_bucket.file_uploads.id
        },
        {
          name  = "MAX_FILE_SIZE_MB"
          value = "40"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}



# App Frontend Task Definition (Next.js)
resource "aws_ecs_task_definition" "app_frontend" {
  family                   = "${var.app_name}-app-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  tags = {
    Name        = "${var.app_name}-app-frontend-task"
    Description = "Task definition for Next.js app-frontend service"
  }

  container_definitions = jsonencode([
    {
      name      = "app-frontend"
      image     = local.app_frontend_image
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "PORT"
          value = "3000"
        },
        {
          name  = "BACKEND_URL"
          value = "http://backend.${var.app_name}.local:3000"
        },
        {
          name  = "NEXT_PUBLIC_BACKEND_URL"
          value = "http://backend.${var.app_name}.local:3000"
        },
        {
          name  = "COGNITO_DOMAIN"
          value = "${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com"
        },
        {
          name  = "COGNITO_CLIENT_ID"
          value = aws_cognito_user_pool_client.client.id
        },
        {
          name  = "ALB_DNS"
          value = aws_lb.main.dns_name
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app_frontend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# Backend Service
resource "aws_ecs_service" "backend" {
  name            = "${var.app_name}-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 0
  launch_type     = "FARGATE"
  enable_execute_command = false

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.backend.arn
  }

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.app_name}-backend-service"
      Description = "FastAPI backend service for internal VPC communication"
    }
  )
}

# App Frontend Service (ALB-authenticated)
resource "aws_ecs_service" "app_frontend" {
  name            = "${var.app_name}-app-frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app_frontend.arn
  desired_count   = 0
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_frontend.arn
    container_name   = "app-frontend"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.https]

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.app_name}-app-frontend-service"
      Description = "Next.js app-frontend service accessible through ALB with Cognito authentication"
    }
  )
}

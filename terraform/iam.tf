# ECS Task Execution Role (for pulling images, logging)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.app_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-ecs-task-execution-role"
    Description = "Execution role for ECS tasks - allows ECR pulls and CloudWatch logs"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy to allow creating CloudWatch log groups
resource "aws_iam_policy" "ecs_task_execution_logs" {
  name        = "${var.app_name}-ecs-task-execution-logs"
  description = "Allow ECS tasks to create CloudWatch log groups"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/ecs/${var.app_name}-*"
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-ecs-task-execution-logs"
    Description = "Allows ECS tasks to create CloudWatch log groups"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_logs" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_logs.arn
}

# Policy to enable ECS Exec (SSM Session Manager)
resource "aws_iam_policy" "ecs_exec" {
  name        = "${var.app_name}-ecs-exec"
  description = "Allow ECS Exec to connect to containers via SSM"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-ecs-exec"
    Description = "Allows ECS Exec to connect to containers via SSM Session Manager"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_ecs_exec" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_exec.arn
}

# ECS Task Role (for the application to access AWS services like DynamoDB)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.app_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-ecs-task-role"
    Description = "Task role for ECS application containers - allows access to DynamoDB and S3"
  }
}

# Policy to access DynamoDB
resource "aws_iam_policy" "dynamodb_access" {
  name        = "${var.app_name}-dynamodb-access"
  description = "Allow access to DynamoDB table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.main.arn
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-dynamodb-access"
    Description = "Allows ECS tasks to perform CRUD operations on DynamoDB table"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_dynamodb" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

# Policy to access S3 bucket for file uploads
resource "aws_iam_policy" "s3_file_access" {
  name        = "${var.app_name}-s3-file-access"
  description = "Allow access to S3 file uploads bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${var.app_name}-file-uploads-*",
          "arn:aws:s3:::${var.app_name}-file-uploads-*/users/*"
        ]
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-s3-file-access"
    Description = "Allows ECS tasks to read/write files to S3 uploads bucket"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_s3" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.s3_file_access.arn
}

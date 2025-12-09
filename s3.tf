# S3 Bucket for file storage
resource "aws_s3_bucket" "file_uploads" {
  bucket        = "${var.app_name}-file-uploads-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.app_name}-file-uploads"
      Description = "S3 bucket for user file uploads with versioning and encryption"
    }
  )
}

# Block all public access to the bucket
resource "aws_s3_bucket_public_access_block" "file_uploads" {
  bucket = aws_s3_bucket.file_uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for data protection
resource "aws_s3_bucket_versioning" "file_uploads" {
  bucket = aws_s3_bucket.file_uploads.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enforce encryption at rest (default AES-256)
resource "aws_s3_bucket_server_side_encryption_configuration" "file_uploads" {
  bucket = aws_s3_bucket.file_uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bucket policy: only allow backend task role to access files under users/* prefix
resource "aws_s3_bucket_policy" "file_uploads" {
  bucket = aws_s3_bucket.file_uploads.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBackendECSTaskRole"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ecs_task_role.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.file_uploads.arn,
          "${aws_s3_bucket.file_uploads.arn}/users/*"
        ]
      }
    ]
  })
}

# Optional: lifecycle policy to auto-delete old file versions after 90 days (for cost optimization)
resource "aws_s3_bucket_lifecycle_configuration" "file_uploads" {
  bucket = aws_s3_bucket.file_uploads.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  rule {
    id     = "abort-incomplete-multipart-upload"
    status = "Enabled"
    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

#!/bin/bash
set -e

# Get app_name from terraform/terraform.tfvars
APP_NAME=$(grep '^app_name' terraform/terraform.tfvars | cut -d'=' -f2 | tr -d ' "')
AWS_REGION=$(grep '^aws_region' terraform/terraform.tfvars | cut -d'=' -f2 | tr -d ' "' || echo "us-east-1")
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
IMAGE_NAME="${APP_NAME}-app-frontend"
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_NAME}:latest"

echo "Building Docker image for linux/amd64..."
cd /Users/ronen/dev/cr8labs/bidflowapp/bidflow-client
BACKEND_URL="http://backend.${APP_NAME}.local:3000"
docker build --platform linux/amd64 \
  --build-arg NEXT_PUBLIC_BACKEND_URL="${BACKEND_URL}" \
  -t ${IMAGE_NAME}:latest .

echo "Tagging image..."
docker tag ${IMAGE_NAME}:latest ${ECR_URI}

echo "Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

echo "Pushing image to ECR..."
docker push ${ECR_URI}

echo "Forcing ECS deployment..."
aws ecs update-service \
  --cluster ${APP_NAME}-cluster \
  --service ${APP_NAME}-app-frontend-service \
  --force-new-deployment \
  --region ${AWS_REGION} \
  --no-cli-pager

echo "✅ Deployment initiated. Wait 2-3 minutes for the new task to become healthy."

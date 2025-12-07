#!/bin/bash
set -e

AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
IMAGE_NAME="my-app-app-frontend"
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_NAME}:latest"

echo "Building Docker image for linux/amd64..."
cd app-frontend
docker build --platform linux/amd64 -t ${IMAGE_NAME}:latest .

echo "Tagging image..."
docker tag ${IMAGE_NAME}:latest ${ECR_URI}

echo "Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

echo "Pushing image to ECR..."
docker push ${ECR_URI}

echo "Forcing ECS deployment..."
aws ecs update-service \
  --cluster my-secure-app-cluster \
  --service my-secure-app-app-frontend-service \
  --force-new-deployment \
  --region ${AWS_REGION} \
  --no-cli-pager

echo "✅ Deployment initiated. Wait 2-3 minutes for the new task to become healthy."

#!/bin/bash
set -e

APP_NAME="my-secure-3"
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "🧹 Cleaning up AWS resources for ${APP_NAME}..."

# Empty and delete S3 bucket
BUCKET_NAME="${APP_NAME}-file-uploads-${AWS_ACCOUNT_ID}"
echo "Emptying S3 bucket: ${BUCKET_NAME}"
aws s3 rm s3://${BUCKET_NAME} --recursive --region ${AWS_REGION} 2>/dev/null || true
aws s3api delete-bucket --bucket ${BUCKET_NAME} --region ${AWS_REGION} 2>/dev/null || true

# Delete ECS services
echo "Deleting ECS services..."
aws ecs update-service --cluster ${APP_NAME}-cluster --service ${APP_NAME}-app-frontend-service --desired-count 0 --region ${AWS_REGION} 2>/dev/null || true
aws ecs update-service --cluster ${APP_NAME}-cluster --service ${APP_NAME}-backend-service --desired-count 0 --region ${AWS_REGION} 2>/dev/null || true
aws ecs delete-service --cluster ${APP_NAME}-cluster --service ${APP_NAME}-app-frontend-service --force --region ${AWS_REGION} 2>/dev/null || true
aws ecs delete-service --cluster ${APP_NAME}-cluster --service ${APP_NAME}-backend-service --force --region ${AWS_REGION} 2>/dev/null || true

# Delete ECS cluster
echo "Deleting ECS cluster..."
aws ecs delete-cluster --cluster ${APP_NAME}-cluster --region ${AWS_REGION} 2>/dev/null || true

# Delete ALB listeners
echo "Deleting ALB..."
ALB_ARN=$(aws elbv2 describe-load-balancers --names ${APP_NAME}-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text --region ${AWS_REGION} 2>/dev/null || echo "")
if [ ! -z "$ALB_ARN" ] && [ "$ALB_ARN" != "None" ]; then
  aws elbv2 describe-listeners --load-balancer-arn ${ALB_ARN} --query 'Listeners[*].ListenerArn' --output text --region ${AWS_REGION} | xargs -n1 aws elbv2 delete-listener --listener-arn --region ${AWS_REGION} 2>/dev/null || true
  aws elbv2 delete-load-balancer --load-balancer-arn ${ALB_ARN} --region ${AWS_REGION} 2>/dev/null || true
fi

# Delete target groups
echo "Deleting target groups..."
TG_ARN=$(aws elbv2 describe-target-groups --names ${APP_NAME}-app-frontend-tg --query 'TargetGroups[0].TargetGroupArn' --output text --region ${AWS_REGION} 2>/dev/null || echo "")
if [ ! -z "$TG_ARN" ] && [ "$TG_ARN" != "None" ]; then
  sleep 10
  aws elbv2 delete-target-group --target-group-arn ${TG_ARN} --region ${AWS_REGION} 2>/dev/null || true
fi

# Delete DynamoDB table
echo "Deleting DynamoDB table..."
aws dynamodb delete-table --table-name ${APP_NAME}-table --region ${AWS_REGION} 2>/dev/null || true

# Delete CloudWatch log groups
echo "Deleting CloudWatch log groups..."
aws logs delete-log-group --log-group-name /ecs/${APP_NAME}-backend --region ${AWS_REGION} 2>/dev/null || true
aws logs delete-log-group --log-group-name /ecs/${APP_NAME}-app-frontend --region ${AWS_REGION} 2>/dev/null || true

# Delete IAM roles and policies
echo "Deleting IAM resources..."
aws iam detach-role-policy --role-name ${APP_NAME}-ecs-task-execution-role --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${APP_NAME}-ecs-task-execution-logs --region ${AWS_REGION} 2>/dev/null || true
aws iam delete-policy --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${APP_NAME}-ecs-task-execution-logs 2>/dev/null || true
aws iam delete-role --role-name ${APP_NAME}-ecs-task-execution-role 2>/dev/null || true
aws iam delete-role --role-name ${APP_NAME}-ecs-task-role 2>/dev/null || true

# Delete AppRegistry resources
echo "Deleting AppRegistry resources..."
aws servicecatalogappregistry delete-application --application ${APP_NAME} --region ${AWS_REGION} 2>/dev/null || true
aws servicecatalogappregistry delete-attribute-group --attribute-group ${APP_NAME}-attributes --region ${AWS_REGION} 2>/dev/null || true

# Delete Resource Group
echo "Deleting Resource Group..."
aws resource-groups delete-group --group-name ${APP_NAME}-resources --region ${AWS_REGION} 2>/dev/null || true

echo "✅ Cleanup complete! Now run: rm -rf .terraform* terraform.tfstate* && terraform init"

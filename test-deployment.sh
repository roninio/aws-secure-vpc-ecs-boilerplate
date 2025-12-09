#!/bin/bash
set -e

echo "🧪 Testing deployment..."

ALB_DNS=$(terraform output -raw alb_dns_name)
CLUSTER="my-secure-app-cluster"
REGION="us-east-1"

echo "✓ ALB DNS: $ALB_DNS"

echo "Checking ECS services..."
SERVICES=$(aws ecs describe-services --cluster $CLUSTER --services my-secure-app-app-frontend-service my-secure-app-backend-service --region $REGION --query 'services[*].[serviceName,runningCount,desiredCount]' --output text)

echo "$SERVICES" | while read name running desired; do
  if [ "$running" -eq "$desired" ] && [ "$running" -gt 0 ]; then
    echo "✅ $name: $running/$desired tasks running"
  else
    echo "❌ $name: $running/$desired tasks running"
    exit 1
  fi
done

echo "Testing ALB health..."
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://$ALB_DNS)
if [ "$HTTP_CODE" -eq 302 ] || [ "$HTTP_CODE" -eq 200 ]; then
  echo "✅ ALB is responding (HTTP $HTTP_CODE)"
else
  echo "❌ ALB returned HTTP $HTTP_CODE"
  exit 1
fi

echo "✅ All services are up and running!"

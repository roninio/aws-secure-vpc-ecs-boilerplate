#!/bin/bash
set -euo pipefail

echo "🧪 Testing deployment..."

if ! command -v jq >/dev/null 2>&1; then
  echo "❌ jq is required but not installed."
  exit 1
fi

echo "Fetching Terraform outputs..."
TF_OUTPUT=$(terraform output -json)

get_output() {
  echo "$TF_OUTPUT" | jq -r --arg key "$1" '.[$key].value'
}

require_output() {
  local key="$1"
  local value
  value=$(get_output "$key")
  if [ "$value" = "null" ] || [ -z "$value" ]; then
    echo "❌ Missing Terraform output: $key"
    exit 1
  fi
  echo "$value"
}

ALB_DNS=$(require_output "alb_dns_name")
REGION=$(require_output "aws_region")
APP_FRONTEND_SERVICE=$(require_output "app_frontend_service_name")
BACKEND_SERVICE=$(require_output "backend_service_name")
CLUSTER=$(get_output "ecs_cluster_name")

if [ "$CLUSTER" = "null" ] || [ -z "$CLUSTER" ]; then
  # Derive cluster name from the service name pattern "<app>-app-frontend-service" -> "<app>-cluster"
  base_name="${APP_FRONTEND_SERVICE%-app-frontend-service}"
  if [ -n "$base_name" ]; then
    CLUSTER="${base_name}-cluster"
    echo "ℹ️ Derived ECS cluster name: $CLUSTER"
  else
    echo "❌ Could not derive ECS cluster name from service name: $APP_FRONTEND_SERVICE"
    exit 1
  fi
fi

echo "✓ ALB DNS: $ALB_DNS"
echo "✓ Cluster: $CLUSTER"
echo "✓ Region: $REGION"

echo "Checking ECS services..."
SERVICES=$(aws ecs describe-services --cluster "$CLUSTER" --services "$APP_FRONTEND_SERVICE" "$BACKEND_SERVICE" --region "$REGION" --query 'services[*].[serviceName,runningCount,desiredCount]' --output text)

echo "$SERVICES" | while read name running desired; do
  if [ "$running" -eq "$desired" ] && [ "$running" -gt 0 ]; then
    echo "✅ $name: $running/$desired tasks running"
  else
    echo "❌ $name: $running/$desired tasks running"
    exit 1
  fi
done

echo "Testing ALB health..."
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" "https://${ALB_DNS}")
if [ "$HTTP_CODE" -eq 302 ] || [ "$HTTP_CODE" -eq 200 ]; then
  echo "✅ ALB is responding (HTTP $HTTP_CODE)"
else
  echo "❌ ALB returned HTTP $HTTP_CODE"
  exit 1
fi

echo "✅ All services are up and running!"

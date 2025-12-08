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

# Tag resources with Application tag for AppRegistry grouping
# This creates automatic associations in AppRegistry dashboard
resource "aws_resourcegroups_group" "application_resources" {
  name               = "${var.app_name}-resources"
  resource_query {
    query = jsonencode({
      ResourceTypeFilters = [
        "AWS::EC2::Instance",
        "AWS::EC2::NetworkInterface",
        "AWS::RDS::DBInstance",
        "AWS::ElastiCache::CacheCluster",
        "AWS::Lambda::Function",
        "AWS::ECS::Service",
        "AWS::ECS::Cluster",
        "AWS::EC2::SecurityGroup",
        "AWS::S3::Bucket",
        "AWS::DynamoDB::Table",
        "AWS::ElasticLoadBalancingV2::LoadBalancer",
        "AWS::Cognito::UserPool"
      ]
      TagFilters = [
        {
          Key    = "Application"
          Values = [var.app_name]
        }
      ]
    })
    type = "TAG_FILTERS_1_0"
  }

  tags = {
    Name = "${var.app_name}-resources"
  }
}

# Local-exec provisioner to tag resources with awsApplication tag for AppRegistry integration
resource "null_resource" "tag_resources_for_appregistry" {
  depends_on = [
    aws_servicecatalogappregistry_application.main,
    aws_resourcegroups_group.application_resources
  ]

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      REGION="${var.aws_region}"
      APP_NAME="${var.app_name}"
      
      # Get the application ARN
      APP_ARN=$(aws servicecatalog-appregistry get-application \
        --application "$APP_NAME" \
        --region "$REGION" \
        --query 'applicationTag.awsApplication' \
        --output text)
      
      echo "AppRegistry Application ARN: $APP_ARN"
      
      # Tag ECS Services
      aws ecs tag-resource \
        --resource-arn "arn:aws:ecs:$REGION:${data.aws_caller_identity.current.account_id}:service/my-secure-app-cluster/my-secure-app-backend-service" \
        --tags key=awsApplication,value="$APP_ARN" \
        --region "$REGION" || echo "Warning: Could not tag backend service"
      
      aws ecs tag-resource \
        --resource-arn "arn:aws:ecs:$REGION:${data.aws_caller_identity.current.account_id}:service/my-secure-app-cluster/my-secure-app-app-frontend-service" \
        --tags key=awsApplication,value="$APP_ARN" \
        --region "$REGION" || echo "Warning: Could not tag app-frontend service"
      
      # Tag ECS Cluster
      aws ecs tag-resource \
        --resource-arn "arn:aws:ecs:$REGION:${data.aws_caller_identity.current.account_id}:cluster/my-secure-app-cluster" \
        --tags key=awsApplication,value="$APP_ARN" \
        --region "$REGION" || echo "Warning: Could not tag ECS cluster"
      
      # Tag S3 Bucket - need to preserve existing tags
      BUCKET_NAME="my-secure-app-file-uploads-${data.aws_caller_identity.current.account_id}"
      
      # Get existing tags and add awsApplication tag
      aws s3api get-bucket-tagging --bucket "$BUCKET_NAME" --region "$REGION" 2>/dev/null | \
        jq ".TagSet += [{Key:\"awsApplication\",Value:\"$APP_ARN\"}]" | \
        jq -r '.TagSet | map("Key=\(.Key),Value=\(.Value)") | join(" ")' | \
        xargs -I {} aws s3api put-bucket-tagging --bucket "$BUCKET_NAME" --tagging "TagSet=[{}]" --region "$REGION" 2>/dev/null || \
        echo "Warning: Could not tag S3 bucket"
      
      # Tag DynamoDB Table
      aws dynamodb tag-resource \
        --resource-arn "arn:aws:dynamodb:$REGION:${data.aws_caller_identity.current.account_id}:table/my-secure-app-table" \
        --tags Key=awsApplication,Value="$APP_ARN" \
        --region "$REGION" || echo "Warning: Could not tag DynamoDB table"
      
      # Tag ALB
      ALB_ARN=$(aws elbv2 describe-load-balancers --names "my-secure-app-alb" --region "$REGION" --query "LoadBalancers[0].LoadBalancerArn" --output text 2>/dev/null)
      if [ ! -z "$ALB_ARN" ] && [ "$ALB_ARN" != "None" ]; then
        aws elbv2 add-tags --resource-arns "$ALB_ARN" --tags Key=awsApplication,Value="$APP_ARN" --region "$REGION" || echo "Warning: Could not tag ALB"
      else
        echo "Warning: Could not find ALB"
      fi
      
      # Tag Security Group - find it dynamically
      SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=my-secure-app-alb-sg" --region "$REGION" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)
      if [ ! -z "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
        aws ec2 create-tags --resources "$SG_ID" --tags "Key=awsApplication,Value=$APP_ARN" --region "$REGION" || echo "Warning: Could not tag security group"
      else
        echo "Warning: Could not find security group"
      fi
      
      echo "AppRegistry integration tagging complete"
    EOT
  }
}


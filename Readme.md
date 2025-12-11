# AWS Secure VPC + ECS Boilerplate

[![Terraform](https://img.shields.io/badge/Terraform-1.0+-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-ECS%20%7C%20Fargate-FF9900?logo=amazon-aws)](https://aws.amazon.com/)
[![Next.js](https://img.shields.io/badge/Next.js-14-000000?logo=next.js)](https://nextjs.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-Backend-009688?logo=fastapi)](https://fastapi.tiangolo.com/)

Production-ready Terraform boilerplate for deploying containerized applications on AWS with secure networking, authentication, and data storage. Includes working Next.js frontend and FastAPI backend for fast testing.

## What's Included

**AWS Services:**
- VPC with public/private subnets across 2 AZs
- ECS Fargate (serverless containers)
- Application Load Balancer with HTTPS
- Cognito authentication (OAuth 2.0)
- DynamoDB (NoSQL database)
- S3 (file storage with presigned URLs)
- CloudWatch Logs
- Service Discovery (AWS Cloud Map)

**Sample Applications:**
- Next.js 14 frontend (TypeScript, React 18)
- FastAPI backend (Python, async)
- User authentication flow
- CRUD operations with DynamoDB
- File upload/download with S3

## Architecture

```
Internet → ALB (HTTPS + Cognito Auth) → Frontend (Next.js) → Backend (FastAPI) → DynamoDB/S3
                                           ↓ Private Subnets ↓
```

**Security:**
- ALB handles authentication (Cognito OAuth 2.0)
- All containers in private subnets
- User info passed via HTTP headers
- Service-to-service communication via AWS Cloud Map
- IAM roles with least privilege

**Infrastructure (~35 AWS resources):**
- VPC: 2 public + 2 private subnets across 2 AZs
- ECS Fargate: Frontend (0.5 vCPU/1GB) + Backend (0.25 vCPU/0.5GB)
- ALB with self-signed SSL certificate
- Cognito User Pool with hosted UI
- DynamoDB (pay-per-request)
- S3 with versioning and presigned URLs
- CloudWatch Logs (7-day retention)

## Quick Start

### Prerequisites
- AWS Account with admin permissions
- Terraform 1.0+
- AWS CLI configured (`aws configure`)
- Docker
- Node.js 18+ (for local dev)
- Python 3.9+ (for local dev)

### Deploy (5 minutes)

```bash
# 1. Clone and configure
git clone <repo>
cd aws-secure-vpc-ecs-boilerplate

# 2. Set AWS credentials
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# 3. Create terraform.tfvars
cat > terraform.tfvars <<EOF
aws_region            = "us-east-1"
app_name              = "my-app"
cognito_domain_prefix = "my-app-auth"
EOF

# 4. Deploy infrastructure
terraform init
terraform apply

# 5. Build and push containers
./deploy-frontend.sh
./deploy-backend.sh

# 6. Get application URL
terraform output alb_dns_name
# Open https://<alb_dns_name> in browser
```

### Configuration Variables

| Variable | Description | Required |
| :--- | :--- | :---: |
| `aws_region` | AWS Region | No (default: us-east-1) |
| `app_name` | Resource name prefix | No (default: my-secure-app) |
| `cognito_domain_prefix` | Cognito hosted UI domain prefix - | **Yes** |

**Note:** Cognito domain prefix must be globally unique. A random suffix is auto-appended.

## Features

**Authentication:**
- Email/password signup and login
- OAuth 2.0 authorization code flow
- Session management with logout

**Sample App Functionality:**
- User profile display
- Text storage (DynamoDB CRUD)
- File upload/download (S3 with presigned URLs, 40MB limit)
- User-scoped file access

**API Endpoints:**
```
GET  /health              # Health check
POST /save                # Save text to DynamoDB
GET  /items               # List all items
POST /upload              # Upload file to S3
GET  /download/{file_id}  # Get presigned download URL
GET  /files               # List user's files
DELETE /files/{file_id}   # Delete file
```

## Usage

```bash
# Get application URL
terraform output alb_dns_name

# Open https://<alb_dns_name> in browser
# Accept self-signed certificate warning
# Sign up with email and password
# Test features: user info, text saver, file upload
```

## Local Development

```bash
# Frontend
cd app-frontend && npm install && npm run dev

# Backend
cd backend && pip install -r requirements.txt
uvicorn main:app --reload --port 3000
```

## Makefile Commands

```bash
make init              # Initialize Terraform
make apply             # Deploy infrastructure
make deploy-all        # Build and push both containers
make logs-frontend     # View frontend logs
make logs-backend      # View backend logs
make destroy           # Destroy all resources
```

## Troubleshooting

```bash
# View logs
aws logs tail /ecs/my-app-app-frontend --follow
aws logs tail /ecs/my-app-backend --follow

# Check ECS service status
aws ecs describe-services --cluster my-app-cluster --services my-app-app-frontend-service
```

**Common Issues:**
- Certificate warning: Expected with self-signed cert (use custom domain for production)
- Tasks not starting: Check CloudWatch logs and IAM permissions
- Health checks failing: Verify containers listen on port 3000

## Production Checklist

- [ ] Use custom domain with valid ACM certificate
- [ ] Enable AWS WAF on ALB
- [ ] Use AWS Secrets Manager for sensitive data
- [ ] Enable VPC Flow Logs
- [ ] Set up CloudWatch alarms
- [ ] Enable GuardDuty
- [ ] Multi-AZ NAT Gateways
- [ ] Enable DynamoDB point-in-time recovery
- [ ] Implement auto-scaling policies

## Cost Estimate

**Monthly (us-east-1):** ~$70-95
- ECS Fargate: $20-35
- ALB: $16-20
- NAT Gateway: $32
- DynamoDB: Pay-per-request (minimal)
- S3: Pay-per-request (minimal)
- CloudWatch Logs: $0.50-5

**Reduce costs:** Use VPC endpoints, scale down during off-hours, leverage AWS Free Tier

## Cleanup

```bash
terraform destroy

# Manually delete ECR repositories
aws ecr delete-repository --repository-name my-app-app-frontend --force
aws ecr delete-repository --repository-name my-app-backend --force
```

## Project Structure

```
├── app-frontend/          # Next.js 14 frontend
│   ├── app/               # App router, components, API routes
│   └── Dockerfile
├── backend/              # FastAPI backend
│   ├── main.py
│   ├── requirements.txt
│   └── Dockerfile
├── *.tf                  # Terraform modules
├── deploy-*.sh           # Deployment scripts
├── Makefile
└── terraform.tfvars      # Your configuration
```

**Terraform Modules:**
- `vpc.tf` - VPC, subnets, NAT Gateway
- `alb.tf` - Load balancer with Cognito auth
- `ecs.tf` - Fargate services and task definitions
- `cognito.tf` - User pool and client
- `dynamodb.tf` - NoSQL table
- `s3.tf` - File storage bucket
- `iam.tf` - Roles and policies
- `security_groups.tf` - Network security
- `service_discovery.tf` - AWS Cloud Map

## Customization

**Replace sample apps:**
1. Update `app-frontend/` and `backend/` with your code
2. Ensure containers expose port 3000
3. Rebuild and push: `./deploy-frontend.sh && ./deploy-backend.sh`

**Add services:**
1. Duplicate task definition in `ecs.tf`
2. Add service discovery entry
3. Update security groups

**Scale services:**
```bash
# Edit desired_count in ecs.tf, or:
aws ecs update-service --cluster my-app-cluster \
  --service my-app-app-frontend-service --desired-count 2
```

**Custom domain:**
1. Request ACM certificate for your domain
2. Update `certificate.tf` with ACM ARN
3. Create Route 53 alias to ALB
4. Update Cognito callback URLs

## License

MIT License

---

**Built by Ronen Azachi** | Terraform + AWS


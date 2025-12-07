# Secure Web Application on AWS with Terraform

[![Terraform](https://img.shields.io/badge/Terraform-1.0+-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-ECS%20%7C%20Fargate-FF9900?logo=amazon-aws)](https://aws.amazon.com/)
[![Next.js](https://img.shields.io/badge/Next.js-14-000000?logo=next.js)](https://nextjs.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-Backend-009688?logo=fastapi)](https://fastapi.tiangolo.com/)

✅ **FULLY DEPLOYED & OPERATIONAL**

This repository contains Terraform infrastructure-as-code to deploy a secure, scalable web application on Amazon Web Services (AWS) using Amazon ECS (Fargate), AWS Cognito for authentication, and an Application Load Balancer (ALB) with HTTPS support.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Technology Stack](#technology-stack)
- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
- [Deployment Steps](#deployment-steps)
- [Accessing the Application](#accessing-the-application)
- [Local Development](#local-development)
- [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)
- [Security Considerations](#security-considerations)
- [Cost Optimization](#cost-optimization)
- [Cleanup](#cleanup)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

## Architecture Overview

The infrastructure deploys a modern, production-ready web application with the following components:

### **Architecture Flow**

```
Internet
   │
   ▼
[Application Load Balancer (ALB)]
   │ HTTPS (443) + Cognito Auth
   ▼
[AWS Cognito] ◄──────────────────┐
   │ (Authentication)              │
   │                               │
   ▼ (Authenticated)               │
[App Frontend Service] ──► [Backend Service] ──► [DynamoDB]
   (Private Subnet)         (Private Subnet)
```

**Key Security Features:**
1. **ALB-Based Authentication** - Cognito authentication handled at ALB layer before routing
2. **App Frontend Service** - Receives authenticated requests with user info in headers
3. **Backend Service** - Completely isolated within VPC
4. **No Separate Login Service** - Authentication managed by ALB, simplifying architecture
5. All services deployed in private subnets with NAT Gateway for outbound access

### **Compute Layer (ECS Fargate)** ✅ DEPLOYED
*   **App Frontend Service**: Main application frontend (Next.js 14)
    *   ✅ Runs on Fargate with 512 CPU / 1024 MB memory
    *   ✅ Deployed in private subnets behind ALB
    *   ✅ Receives authenticated requests with user info in HTTP headers
    *   ✅ Headers: `x-amzn-oidc-data`, `x-amzn-oidc-identity`, `x-amzn-oidc-accesstoken`
    *   ✅ Accessible via ALB on port 3000 (container)
    *   ✅ Features: User info display, text saver with DynamoDB integration, logout functionality
*   **Backend Service**: FastAPI backend service
    *   ✅ Runs on Fargate with 256 CPU / 512 MB memory
    *   ✅ Deployed in private subnets (no internet exposure)
    *   ✅ Connected to DynamoDB for data persistence
    *   ✅ Accessible only within the VPC via service discovery (backend.my-secure-app.local)
    *   ✅ Endpoints: `/health`, `/save` (POST), `/items` (GET)

### **Load Balancing & SSL/TLS** ✅ DEPLOYED
*   **Application Load Balancer (ALB)**: Public-facing load balancer with integrated authentication
    *   ✅ HTTP (port 80) → Redirects to HTTPS (301)
    *   ✅ HTTPS (port 443) → Authenticates with Cognito → Forwards to app frontend
    *   ✅ Self-signed SSL certificate via AWS Certificate Manager (ACM)
    *   ✅ Deployed across multiple availability zones
    *   ✅ **Security**: Authentication at ALB layer before application access

### **Authentication & Authorization** ✅ DEPLOYED
*   **AWS Cognito User Pool**: Managed user authentication integrated with ALB
    *   ✅ Email-based user registration and login
    *   ✅ Password policy enforcement (8+ chars, uppercase, lowercase, numbers, symbols)
    *   ✅ Customized hosted UI with branded styling
    *   ✅ OAuth 2.0 authorization code flow with client secret (ALB-managed)
    *   ✅ Callback URL: `/oauth2/idpresponse` (ALB endpoint)
    *   ✅ ALB validates tokens and passes user info to application via headers
    *   ✅ Logout functionality with proper session cleanup

### **Networking** ✅ DEPLOYED
*   **VPC**: Custom VPC (10.0.0.0/16) with DNS support
*   **Public Subnets** (2): Host ALB and NAT Gateway
    *   ✅ CIDR: 10.0.0.0/24, 10.0.1.0/24
*   **Private Subnets** (2): Host ECS tasks
    *   ✅ CIDR: 10.0.10.0/24, 10.0.11.0/24
*   **Internet Gateway**: Provides internet access for public subnets
*   **NAT Gateway**: Enables outbound internet access for private subnets (container image pulls, updates)
*   **Security Groups**: Fine-grained traffic control between ALB, ECS tasks, and services
*   **Service Discovery**: AWS Cloud Map private DNS namespace (my-secure-app.local)
    *   ✅ Enables internal service-to-service communication
    *   ✅ Backend registered as: backend.my-secure-app.local

### **Data Storage** ✅ DEPLOYED
*   **Amazon DynamoDB**: Serverless NoSQL database
    *   ✅ Pay-per-request billing mode
    *   ✅ Hash key: `id` (String)
    *   ✅ Integrated with backend service via environment variables
    *   ✅ Stores user-submitted text with timestamps

### **IAM & Security** ✅ DEPLOYED
*   ✅ **ECS Task Execution Role**: Allows ECS to pull images and write logs
*   ✅ **ECS Task Role**: Grants application permissions (DynamoDB access)
*   ✅ **Principle of Least Privilege**: Each service has minimal required permissions

### **Logging & Monitoring** ✅ DEPLOYED
*   **CloudWatch Logs**: Centralized logging for ECS tasks
    *   ✅ App Frontend logs: `/ecs/${app_name}-app-frontend`
    *   ✅ Backend logs: `/ecs/${app_name}-backend`
    *   ✅ Auto-created log groups with 7-day retention
    *   ✅ Stream prefixes for organized log viewing

## Technology Stack

### App Frontend Service ✅ IMPLEMENTED
*   **Next.js 14** with App Router and TypeScript
*   **React 18** with Server Components
*   ✅ Receives authenticated user info from ALB in HTTP headers
*   ✅ Communicates with backend via internal VPC networking
*   ✅ Features:
    *   User info display (email, sub, token expiration)
    *   Text saver component with DynamoDB integration
    *   Logout functionality
    *   Responsive UI with gradient styling

### Backend Service ✅ IMPLEMENTED
*   **FastAPI** (Python 3.9+)
*   **Boto3** AWS SDK for DynamoDB integration
*   **Pydantic** for data validation
*   ✅ CORS enabled for frontend communication
*   ✅ Endpoints:
    *   `GET /health` - Health check
    *   `POST /save` - Save text to DynamoDB
    *   `GET /items` - Retrieve all items from DynamoDB
*   ✅ Structured logging with Python logging module

### Infrastructure ✅ DEPLOYED
*   **Terraform** for infrastructure-as-code
*   **AWS ECS Fargate** for serverless container orchestration
*   **Amazon ECR** for container registry
*   **AWS Cloud Map** for service discovery

## Prerequisites

Before deploying this infrastructure, ensure you have:

*   **AWS Account**: Active AWS account with appropriate permissions
*   **Terraform**: Version 1.0+ installed ([Download](https://www.terraform.io/downloads))
*   **AWS CLI**: Installed and configured with credentials
    ```bash
    aws configure
    ```
*   **Docker**: For building and pushing container images
*   **Node.js**: Version 18+ (for app frontend development)
*   **Python**: Version 3.9+ (for backend development)

## Configuration

The deployment is customized using variables defined in `variables.tf`. Create a `terraform.tfvars` file to set these values:

| Variable | Description | Default | Required |
| :--- | :--- | :--- | :---: |
| `aws_region` | AWS Region for deployment | `us-east-1` | No |
| `app_name` | Name prefix for all resources | `my-secure-app` | No |
| `app_frontend_image` | ECR URI for the app frontend Docker image | `884337373788.dkr.ecr.us-east-1.amazonaws.com/my-app-app-frontend:latest` | No |
| `backend_image` | ECR URI for the backend Docker image | - | **Yes** |
| `cognito_domain_prefix` | Unique prefix for Cognito hosted UI domain | - | **Yes** |
| `additional_callback_urls` | Additional callback URLs for multiple environments | `[]` | No |
| `additional_logout_urls` | Additional logout URLs for multiple environments | `[]` | No |
| `allow_admin_create_user_only` | Only allow admins to create users | `false` | No |

### Important Notes
*   The `cognito_domain_prefix` must be globally unique across AWS
*   A random 6-character suffix is automatically appended to ensure uniqueness
*   App frontend image should expose port 3000
*   Backend image should expose port 3000
*   **Authentication**: ALB handles Cognito authentication; app receives user info in headers

## Deployment Steps

### Step 1: Create ECR Repositories ✅ COMPLETED

ECR repositories are automatically created via Terraform (see `ecr.tf`):

```bash
# Repositories created:
# - my-app-app-frontend
# - my-app-backend

# To manually create if needed:
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws ecr create-repository --repository-name my-app-app-frontend --region $AWS_REGION
aws ecr create-repository --repository-name my-app-backend --region $AWS_REGION
```

### Step 2: Build and Push Docker Images ✅ COMPLETED

Convenience scripts are provided for deployment:
- `deploy-frontend.sh` - Builds and pushes app frontend image
- `deploy-backend.sh` - Builds and pushes backend image

#### Build App Frontend Image

```bash
cd app-frontend

# Build the Docker image
docker build -t my-app-app-frontend:latest .

# Tag for ECR
docker tag my-app-app-frontend:latest \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/my-app-app-frontend:latest

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Push to ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/my-app-app-frontend:latest

cd ..
```

#### Build Backend Image

```bash
cd backend

# Build the Docker image
docker build -t my-app-backend:latest .

# Tag for ECR
docker tag my-app-backend:latest \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/my-app-backend:latest

# Push to ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/my-app-backend:latest

cd ..
```

### Step 3: Configure Terraform Variables

Create a `terraform.tfvars` file in the root directory:

```hcl
aws_region            = "us-east-1"
app_name              = "my-secure-app"
app_frontend_image    = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app-app-frontend:latest"
backend_image         = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app-backend:latest"
cognito_domain_prefix = "my-secure-app-auth"
```

**Replace** `123456789012` with your actual AWS account ID.

### Step 4: Deploy Infrastructure with Terraform

```bash
# Initialize Terraform (downloads providers and modules)
terraform init

# Preview the changes
terraform plan

# Apply the configuration (creates all resources)
terraform apply

# Type 'yes' when prompted to confirm
```

The deployment typically takes **5-10 minutes** to complete.

## Accessing the Application

After successful deployment, Terraform will output important values:

```bash
# View all outputs
terraform output

# Get specific output
terraform output alb_dns_name
```

### Access Steps

1.  **Get the ALB DNS Name**:
    ```bash
    terraform output alb_dns_name
    ```
    Example output: `my-secure-app-alb-1234567890.us-east-1.elb.amazonaws.com`

2.  **Open in Browser**:
    *   Navigate to `https://<alb_dns_name>`
    *   Note: You'll see a browser warning about the self-signed certificate
    *   Click "Advanced" → "Proceed to site" (Chrome) or "Accept the Risk" (Firefox)

3.  **Sign Up / Sign In**:
    *   ALB automatically redirects to AWS Cognito Hosted UI
    *   Click "Sign up" to create a new account
    *   Enter your email and create a password (must meet policy requirements)
    *   Verify your email with the code sent to your inbox

4.  **Access the Application**:
    *   After authentication, ALB redirects you to the app frontend
    *   ✅ User info is displayed on the page (email, sub, token expiration)
    *   ✅ Try the text saver feature to test DynamoDB integration
    *   ✅ Use the logout button to end your session

### Terraform Outputs

| Output | Description | Example Value |
| :--- | :--- | :--- |
| `alb_dns_name` | Public DNS name of the ALB | `my-app-alb-123.us-east-1.elb.amazonaws.com` |
| `cognito_user_pool_id` | Cognito User Pool ID | `us-east-1_aBcDeFgHi` |
| `cognito_client_id` | Cognito App Client ID | `1a2b3c4d5e6f7g8h9i0j` |
| `cognito_domain` | Cognito hosted UI domain | `my-secure-app-auth-123-abc123` |
| `app_frontend_service_name` | ECS App Frontend Service name | `my-secure-app-app-frontend-service` |
| `backend_service_name` | ECS Backend Service name | `my-secure-app-backend-service` |
| `backend_service_url` | Internal backend URL | `http://backend.my-secure-app.local:3000` |

## Local Development

### App Frontend Development

```bash
cd app-frontend

# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build
```

**Note**: In local development, you'll need to handle authentication differently since ALB authentication is not available locally.

### Backend Development

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run development server
uvicorn main:app --reload --port 3000
```

The backend API will run on `http://localhost:3000`.

## Deployment Scripts ✅ AVAILABLE

Convenience scripts for quick deployment:

```bash
# Deploy app frontend
./deploy-frontend.sh

# Deploy backend
./deploy-backend.sh

# Test logout functionality
./test-logout.sh
```

## Monitoring and Troubleshooting

### View ECS Service Status

```bash
# List ECS services
aws ecs list-services --cluster my-secure-app-cluster

# Describe app frontend service
aws ecs describe-services \
  --cluster my-secure-app-cluster \
  --services my-secure-app-app-frontend-service

# Describe backend service
aws ecs describe-services \
  --cluster my-secure-app-cluster \
  --services my-secure-app-backend-service
```

### View CloudWatch Logs

```bash
# App Frontend logs
aws logs tail /ecs/my-secure-app-app-frontend --follow

# Backend logs
aws logs tail /ecs/my-secure-app-backend --follow
```

### Common Issues

#### 1. ECS Tasks Not Starting
*   Check CloudWatch logs for container errors
*   Verify ECR images are accessible
*   Ensure IAM roles have correct permissions

#### 2. ALB Health Checks Failing
*   Verify container is listening on port 3000
*   Check security group rules
*   Review target group health check settings

#### 3. Cognito Authentication Issues
*   Verify callback URL is set to `/oauth2/idpresponse`
*   Check Cognito user pool configuration
*   Ensure Cognito client has `generate_secret = true`

#### 4. Certificate Warnings
*   This is expected with self-signed certificates
*   For production, use a valid domain and ACM-issued certificate

#### 5. Backend Communication Issues
*   Verify service discovery is working: `backend.my-secure-app.local`
*   Check security group allows traffic between ECS tasks
*   Review backend logs for connection errors

## Security Considerations

### Current Implementation ✅ DEPLOYED
*   ✅ HTTPS encryption with self-signed certificate
*   ✅ All ECS tasks in private subnets (no public IPs)
*   ✅ Security groups with minimal required access
*   ✅ IAM roles with least-privilege permissions
*   ✅ ALB-integrated Cognito authentication (OAuth 2.0 code flow)
*   ✅ Authentication at ALB layer before application access
*   ✅ User info passed securely via HTTP headers
*   ✅ Simplified architecture (no separate login service)
*   ✅ Service discovery for internal communication
*   ✅ CORS properly configured for frontend-backend communication



### Production Recommendations
*   🔒 Use a custom domain with valid SSL certificate from ACM
*   🔒 Enable AWS WAF on the ALB
*   🔒 Implement AWS Secrets Manager for sensitive data
*   🔒 Enable VPC Flow Logs for network monitoring
*   🔒 Set up CloudWatch alarms for security events
*   🔒 Enable AWS GuardDuty for threat detection
*   🔒 Implement multi-AZ NAT Gateways for high availability
*   🔒 Use AWS KMS for encryption at rest
*   🔒 Enable DynamoDB point-in-time recovery

## Cost Optimization

### Estimated Monthly Costs (us-east-1)
*   **ECS Fargate**: ~$20-35 (2 tasks: app frontend 0.5 vCPU/1GB + backend 0.25 vCPU/0.5GB)
*   **Application Load Balancer**: ~$16-20
*   **NAT Gateway**: ~$32 (single NAT)
*   **DynamoDB**: Pay-per-request (minimal for dev/test)
*   **CloudWatch Logs**: ~$0.50-5 (depending on log volume)
*   **Data Transfer**: Variable based on usage

**Total**: ~$70-95/month for development environment

### Cost Reduction Tips
*   Use AWS Free Tier where applicable
*   Reduce ECS task count during off-hours
*   Consider using VPC endpoints instead of NAT Gateway for AWS services
*   Set up CloudWatch log retention policies
*   Use AWS Cost Explorer to monitor spending

## Cleanup

To destroy all infrastructure and stop incurring charges:

```bash
# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Type 'yes' when prompted to confirm
```

**Warning**: This will permanently delete:
*   All ECS services and tasks
*   The Application Load Balancer
*   VPC and networking components
*   Cognito User Pool (and all users)
*   DynamoDB table (and all data)

**Note**: ECR repositories and container images are NOT automatically deleted. To remove them:

```bash
# Delete ECR repositories
aws ecr delete-repository --repository-name my-app-app-frontend --force
aws ecr delete-repository --repository-name my-app-backend --force
```

## Project Structure ✅ CURRENT

```
aws-terra/
├── app-frontend/                # Next.js 14 frontend (ALB-authenticated) ✅
│   ├── app/                    # Next.js app directory
│   │   ├── api/                # API routes
│   │   ├── components/         # React components (UserInfo, TextSaver, LogoutButton)
│   │   ├── logout-success/     # Logout success page
│   │   ├── layout.tsx          # Root layout
│   │   └── page.tsx            # Home page
│   ├── Dockerfile              # App frontend container image
│   ├── package.json            # Dependencies (Next.js 14, React 18)
│   └── tsconfig.json           # TypeScript configuration
│
├── backend/                     # FastAPI backend (internal, VPC) ✅
│   ├── main.py                 # FastAPI application with /health, /save, /items
│   ├── requirements.txt        # Python dependencies (fastapi, boto3, uvicorn)
│   └── Dockerfile              # Backend container image
│
├── userlogin/                   # Legacy - kept for reference
│   └── (React + Vite app)
│
├── alb.tf                      # Application Load Balancer with Cognito auth ✅
├── appregistry.tf              # AWS Service Catalog App Registry
├── certificate.tf              # Self-signed SSL certificate ✅
├── cognito.tf                  # AWS Cognito User Pool and Client ✅
├── dynamodb.tf                 # DynamoDB table configuration ✅
├── ecr.tf                      # ECR repositories ✅
├── ecs.tf                      # ECS cluster, task definitions, and services ✅
├── iam.tf                      # IAM roles and policies ✅
├── outputs.tf                  # Terraform output values ✅
├── provider.tf                 # AWS provider configuration ✅
├── security_groups.tf          # Security group rules ✅
├── service_discovery.tf        # AWS Cloud Map configuration ✅
├── variables.tf                # Input variables ✅
├── vpc.tf                      # VPC, subnets, and networking ✅
│
├── deploy-frontend.sh          # Deployment script for app frontend ✅
├── deploy-backend.sh           # Deployment script for backend ✅
├── test-logout.sh              # Logout functionality test script ✅
├── terraform.tfvars            # Variable values (gitignored)
├── MIGRATION.md                # Migration guide to ALB authentication
└── README.md                   # This file
```

## Infrastructure Resources Created

This Terraform configuration creates the following AWS resources:

| Resource Type | Count | Purpose |
| :--- | :---: | :--- |
| VPC | 1 | Network isolation |
| Subnets | 4 | 2 public + 2 private across 2 AZs |
| Internet Gateway | 1 | Public internet access |
| NAT Gateway | 1 | Outbound internet for private subnets |
| Elastic IP | 1 | For NAT Gateway |
| Route Tables | 2 | Public and private routing |
| Security Groups | 2 | ALB and ECS task security |
| Application Load Balancer | 1 | Traffic distribution + authentication |
| Target Group | 1 | App frontend service targets |
| ALB Listeners | 2 | HTTP (redirect) + HTTPS (with Cognito auth) |
| ACM Certificate | 1 | Self-signed SSL certificate |
| ECS Cluster | 1 | Container orchestration |
| ECS Task Definitions | 2 | App Frontend + Backend |
| ECS Services | 2 | App Frontend (ALB) + Backend (VPC) |
| Service Discovery Namespace | 1 | Private DNS namespace |
| Service Discovery Service | 1 | Backend service registration |
| IAM Roles | 2 | Task execution + Task role |
| IAM Policies | 2+ | Permissions for ECS and DynamoDB |
| Cognito User Pool | 1 | User authentication |
| Cognito User Pool Client | 1 | OAuth application (ALB-integrated) |
| Cognito Domain | 1 | Hosted UI domain |
| DynamoDB Table | 1 | Application data storage |
| CloudWatch Log Groups | 2 | ECS task logs |

**Total**: ~32-36 resources

## Updating the Infrastructure

### Update ECS Task Configuration

To change CPU/memory allocation or environment variables:

1. Edit the relevant section in `ecs.tf`
2. Apply changes:
```bash
terraform apply
```

### Update Container Images

To deploy new versions of your application:

```bash
# Build and push new images (see Step 2 in Deployment)
# Then force new deployment
aws ecs update-service \
  --cluster my-secure-app-cluster \
  --service my-secure-app-app-frontend-service \
  --force-new-deployment
```

### Scale Services

To change the number of running tasks:

```bash
# Update desired_count in ecs.tf
# Or use AWS CLI
aws ecs update-service \
  --cluster my-secure-app-cluster \
  --service my-secure-app-app-frontend-service \
  --desired-count 2
```

## Advanced Configuration

### Custom Domain Setup

To use a custom domain instead of the ALB DNS name:

1. Register a domain in Route 53
2. Request a certificate in ACM for your domain
3. Update `certificate.tf` to use the ACM certificate ARN
4. Create a Route 53 alias record pointing to the ALB
5. Update Cognito callback URLs with your custom domain

### Multi-Region Deployment

To deploy in multiple regions:

1. Create a new directory for each region
2. Copy all `.tf` files
3. Update `terraform.tfvars` with region-specific values
4. Deploy separately in each region

### CI/CD Integration

Example GitHub Actions workflow:

```yaml
name: Deploy to AWS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Build and push images
        run: |
          # Build and push user login
          cd userlogin
          docker build -t my-app-userlogin .
          # ... push to ECR
      
      - name: Deploy with Terraform
        run: |
          terraform init
          terraform apply -auto-approve
```

## Troubleshooting Guide

### Issue: "Cognito domain already exists"

**Solution**: The `cognito_domain_prefix` must be globally unique. Change it in `terraform.tfvars` and reapply.

### Issue: "No space left on device" during Docker build

**Solution**: Clean up Docker images and containers:
```bash
docker system prune -a
```

### Issue: ECS tasks are stuck in "PENDING" state

**Possible causes**:
1. ECR image not accessible → Check IAM permissions
2. No available IP addresses → Check subnet CIDR blocks
3. Resource limits → Check AWS service quotas

### Issue: ALB returns 503 errors

**Possible causes**:
1. No healthy targets → Check ECS task health
2. Security group blocking traffic → Verify security group rules
3. Container not listening on correct port → Check Dockerfile EXPOSE

### Issue: Terraform state is locked

**Solution**:
```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

## Best Practices

### Security
*   ✅ Never commit `terraform.tfvars` or `.tfstate` files to version control
*   ✅ Use AWS Secrets Manager for sensitive data
*   ✅ Enable MFA for AWS account
*   ✅ Regularly rotate IAM credentials
*   ✅ Use VPC endpoints for AWS services to avoid NAT Gateway costs

### Infrastructure Management
*   ✅ Use remote state backend (S3 + DynamoDB) for team collaboration
*   ✅ Tag all resources for cost tracking
*   ✅ Use Terraform workspaces for multiple environments
*   ✅ Implement automated testing with Terratest
*   ✅ Document all infrastructure changes

### Application Development
*   ✅ Use environment variables for configuration
*   ✅ Implement health check endpoints
*   ✅ Use structured logging (JSON format)
*   ✅ Implement graceful shutdown handling
*   ✅ Use connection pooling for database access

## FAQ

**Q: Can I use this for production?**
A: This is a solid foundation, but you should implement the production recommendations in the Security Considerations section.

**Q: How do I add more backend services?**
A: Duplicate the backend task definition and service in `ecs.tf`, update the names, and configure service discovery or internal load balancing.

**Q: Can I use RDS instead of DynamoDB?**
A: Yes, create an RDS instance in `database.tf`, update security groups, and modify the backend environment variables.

**Q: How do I enable auto-scaling?**
A: Add `aws_appautoscaling_target` and `aws_appautoscaling_policy` resources to scale based on CPU/memory or custom metrics.

**Q: What if I don't have a backend yet?**
A: You can comment out the backend-related resources in `ecs.tf` and deploy only the app frontend service.

**Q: How does the app frontend communicate with the backend?**
A: ✅ The app frontend service communicates directly with the backend service within the VPC using AWS Cloud Map service discovery (`backend.my-secure-app.local:3000`). Both services are in private subnets with no internet exposure. Security groups allow traffic between ECS tasks.

**Q: How does authentication work?**
A: ✅ The ALB handles all authentication with Cognito. When a user accesses the app, the ALB redirects to Cognito for login, validates the token, and passes user info to the app frontend via HTTP headers (`x-amzn-oidc-data`, `x-amzn-oidc-identity`, `x-amzn-oidc-accesstoken`). The app frontend decodes these headers to display user information.

**Q: What features are currently working?**
A: ✅ All core features are operational:
- User authentication via Cognito
- User info display (email, sub, token expiration)
- Text saver with DynamoDB integration
- Backend API endpoints (/health, /save, /items)
- Logout functionality with session cleanup
- Service discovery for internal communication
- CloudWatch logging for both services

**Q: Can I use a different authentication provider?**
A: Yes, ALB supports OIDC-compliant identity providers. Update the listener action in `alb.tf` to use `authenticate-oidc` instead of `authenticate-cognito`.

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure:
*   Code follows Terraform best practices
*   All resources are properly tagged
*   Documentation is updated
*   Changes are tested in a development environment

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

*   AWS for comprehensive documentation
*   Terraform for infrastructure-as-code capabilities
*   The open-source community for inspiration and best practices

## Quick Start Guide

For first-time users:

1. **Clone and Configure**:
   ```bash
   git clone <repository>
   cd aws-terra
   cp terraform.tfvars.example terraform.tfvars  # Edit with your values
   ```

2. **Deploy Infrastructure**:
   ```bash
   terraform init
   terraform apply
   ```

3. **Build and Deploy Applications**:
   ```bash
   ./deploy-backend.sh
   ./deploy-frontend.sh
   ```

4. **Access Application**:
   ```bash
   terraform output alb_dns_name
   # Open https://<alb_dns_name> in browser
   ```

## Support

For issues and questions:
*   Open an issue in the GitHub repository
*   Check AWS documentation for service-specific questions
*   Review Terraform documentation for configuration syntax
*   See MIGRATION.md for architecture evolution details

## Current Status Summary

### ✅ Fully Operational Components
1. **Infrastructure**: VPC, subnets, NAT Gateway, Internet Gateway
2. **Load Balancing**: ALB with HTTPS and Cognito authentication
3. **Compute**: ECS Fargate cluster with 2 services (app frontend + backend)
4. **Authentication**: Cognito User Pool with hosted UI
5. **Storage**: DynamoDB table with pay-per-request billing
6. **Networking**: Service discovery via AWS Cloud Map
7. **Security**: Security groups, IAM roles, private subnets
8. **Monitoring**: CloudWatch logs with 7-day retention
9. **Container Registry**: ECR repositories for both services

### ✅ Working Features
1. **User Authentication**: Sign up, sign in, email verification
2. **User Info Display**: Email, sub, token expiration
3. **Text Saver**: Save and retrieve text from DynamoDB
4. **Logout**: Proper session cleanup and redirect
5. **Backend API**: Health check, save, and retrieve endpoints
6. **Internal Communication**: Frontend → Backend via service discovery

### 🚧 Known Limitations
1. **Self-signed Certificate**: Browser warnings expected (use custom domain for production)
2. **Single NAT Gateway**: Consider multi-AZ for high availability
3. **No Auto-scaling**: Fixed task count (easily configurable)
4. **Development Environment**: Optimized for dev/test, not production-hardened

### 🚀 Next Steps for Production
1. Use custom domain with valid ACM certificate
2. Enable AWS WAF on ALB
3. Implement auto-scaling policies
4. Add multi-AZ NAT Gateways
5. Enable DynamoDB point-in-time recovery
6. Set up CloudWatch alarms
7. Implement CI/CD pipeline
8. Add comprehensive monitoring and alerting

---

**Written by Ronen Azachi**

**Built with ❤️ using Terraform and AWS**

**Status**: ✅ Fully Deployed and Operational


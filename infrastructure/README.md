# Multi-Tenant Autonomous Agent Platform - AWS Infrastructure

This repository contains the Infrastructure as Code (IaC) implementation for the Multi-Tenant Autonomous Agent Platform using Terraform and AWS services.

## Architecture Overview

The infrastructure implements a hybrid cloud architecture with the following core components:

- **Amazon EKS**: Managed Kubernetes cluster for container orchestration
- **Amazon RDS**: PostgreSQL database for persistent data storage
- **Amazon ElastiCache**: Redis cluster for caching and session management
- **AWS Lambda**: Serverless functions for API endpoints and event processing
- **VPC**: Multi-tier network architecture with public, private, and database subnets
- **Security**: Comprehensive security controls including encryption, access control, and monitoring

## Prerequisites

Before deploying the infrastructure, ensure you have the following tools installed:

- [Terraform](https://www.terraform.io/downloads.html) >= 1.5
- [AWS CLI](https://aws.amazon.com/cli/) >= 2.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (for EKS management)
- [jq](https://stedolan.jq.io/) (for JSON processing)

### AWS Configuration

Configure your AWS credentials using one of the following methods:

```bash
# Option 1: AWS CLI configuration
aws configure

# Option 2: Environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"

# Option 3: IAM roles (recommended for production)
# Use IAM roles with appropriate policies
```

## Quick Start

1. **Clone and navigate to the infrastructure directory:**
   ```bash
   git clone <repository-url>
   cd aws-infrastructure
   ```

2. **Create your configuration:**
   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   # Edit terraform.tfvars with your specific configuration
   ```

3. **Deploy the infrastructure:**
   ```bash
   ./scripts/deploy.sh deploy
   ```

This will automatically:
- Check prerequisites
- Validate Terraform configuration
- Create deployment plan
- Apply the infrastructure
- Configure kubectl for EKS access

## Directory Structure

```
aws-infrastructure/
├── terraform/                 # Terraform configuration files
│   ├── main.tf               # Main infrastructure configuration
│   ├── variables.tf          # Variable definitions
│   ├── outputs.tf            # Output definitions
│   ├── lambda.tf             # Lambda functions configuration
│   ├── secrets.tf            # Secrets management
│   └── terraform.tfvars.example  # Example variables file
├── lambda-functions/         # Lambda function source code
│   └── health-check/         # Health check function
├── lambda-layers/            # Lambda layer dependencies
├── scripts/                  # Deployment and utility scripts
│   └── deploy.sh            # Main deployment script
└── docs/                    # Documentation
```

## Configuration

### Environment Variables

The infrastructure supports multiple environments (dev, staging, prod) through variable configuration:

```hcl
# terraform.tfvars
project_name = "agent-platform"
environment  = "dev"
aws_region   = "us-west-2"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
single_nat_gateway = true  # false for production

# EKS Configuration
kubernetes_version = "1.28"
eks_node_instance_types = ["t3.medium", "t3.large"]

# RDS Configuration
rds_instance_class = "db.t3.medium"
rds_multi_az = true

# ElastiCache Configuration
elasticache_node_type = "cache.t3.medium"
```

### Security Configuration

The infrastructure implements comprehensive security controls:

- **Encryption**: All data encrypted at rest and in transit
- **Network Security**: Multi-tier VPC with security groups and NACLs
- **Access Control**: IAM roles and policies with least privilege
- **Secrets Management**: AWS Secrets Manager for sensitive data
- **Monitoring**: CloudWatch logs and metrics for all components

## Deployment Commands

### Using the Deployment Script

The `deploy.sh` script provides convenient commands for managing the infrastructure:

```bash
# Check prerequisites
./scripts/deploy.sh check-prereqs

# Validate Terraform configuration
./scripts/deploy.sh validate

# Create backend resources (first time only)
./scripts/deploy.sh create-backend --environment dev --region us-west-2

# Plan deployment
./scripts/deploy.sh plan

# Apply deployment
./scripts/deploy.sh apply

# Full deployment (recommended)
./scripts/deploy.sh deploy

# Show outputs
./scripts/deploy.sh outputs

# Configure kubectl
./scripts/deploy.sh configure-kubectl

# Destroy infrastructure
./scripts/deploy.sh destroy
```

### Manual Terraform Commands

You can also use Terraform commands directly:

```bash
cd terraform

# Initialize Terraform
terraform init -backend-config=backend.conf

# Plan deployment
terraform plan -var-file=terraform.tfvars

# Apply deployment
terraform apply -var-file=terraform.tfvars

# Show outputs
terraform output

# Destroy infrastructure
terraform destroy -var-file=terraform.tfvars
```

## Backend Configuration

The infrastructure uses remote state storage with S3 and DynamoDB for state locking:

1. **Create backend resources:**
   ```bash
   ./scripts/deploy.sh create-backend --environment dev
   ```

2. **Initialize Terraform with backend:**
   ```bash
   cd terraform
   terraform init -backend-config=backend.conf
   ```

## Post-Deployment Configuration

After successful deployment:

1. **Configure kubectl:**
   ```bash
   aws eks update-kubeconfig --region us-west-2 --name agent-platform-dev-eks
   ```

2. **Verify cluster connectivity:**
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

3. **Access database:**
   ```bash
   # Get database credentials from Secrets Manager
   aws secretsmanager get-secret-value --secret-id agent-platform-dev-rds-credentials
   ```

4. **Test health endpoints:**
   ```bash
   # Get API Gateway URL from outputs
   terraform output -raw api_gateway_url
   
   # Test health check
   curl https://your-api-gateway-url/dev/health
   ```

## Monitoring and Logging

The infrastructure includes comprehensive monitoring:

- **CloudWatch Logs**: Centralized logging for all components
- **CloudWatch Metrics**: Performance and health metrics
- **AWS X-Ray**: Distributed tracing for Lambda functions
- **VPC Flow Logs**: Network traffic monitoring

Access monitoring dashboards through the AWS Console or configure custom dashboards using the provided metrics.

## Security Best Practices

The infrastructure implements security best practices:

1. **Network Security**:
   - Private subnets for application workloads
   - Database subnets with no internet access
   - Security groups with minimal required access

2. **Encryption**:
   - KMS encryption for all data at rest
   - TLS encryption for all data in transit
   - Customer-managed encryption keys (CMEK) support

3. **Access Control**:
   - IAM roles with least privilege principles
   - Service accounts for Kubernetes workloads
   - Multi-factor authentication support

4. **Secrets Management**:
   - AWS Secrets Manager for sensitive data
   - Automatic secret rotation
   - No hardcoded credentials in configuration

## Cost Optimization

The infrastructure includes cost optimization features:

- **Auto Scaling**: EKS node groups with automatic scaling
- **Spot Instances**: Optional spot instance support for development
- **Resource Tagging**: Comprehensive tagging for cost allocation
- **Storage Optimization**: GP3 volumes with optimized IOPS

Monitor costs using AWS Cost Explorer and set up billing alerts to prevent unexpected charges.

## Troubleshooting

### Common Issues

1. **Terraform State Lock**:
   ```bash
   # Force unlock if needed (use with caution)
   terraform force-unlock <lock-id>
   ```

2. **EKS Node Group Issues**:
   ```bash
   # Check node group status
   aws eks describe-nodegroup --cluster-name <cluster-name> --nodegroup-name <nodegroup-name>
   ```

3. **Database Connection Issues**:
   ```bash
   # Check security groups and network connectivity
   aws rds describe-db-instances --db-instance-identifier <instance-id>
   ```

4. **Lambda Function Errors**:
   ```bash
   # Check CloudWatch logs
   aws logs describe-log-groups --log-group-name-prefix /aws/lambda/
   ```

### Health Checks

The infrastructure includes health check endpoints:

```bash
# Test overall system health
curl https://your-api-gateway-url/dev/health

# Check individual components
kubectl get pods --all-namespaces
aws rds describe-db-instances
aws elasticache describe-replication-groups
```

## Backup and Disaster Recovery

The infrastructure includes automated backup capabilities:

- **RDS**: Automated backups with point-in-time recovery
- **ElastiCache**: Daily snapshots with configurable retention
- **EKS**: Persistent volume snapshots
- **Cross-Region**: Optional cross-region backup replication

## Scaling and Performance

The infrastructure is designed for horizontal scaling:

- **EKS**: Auto-scaling node groups
- **RDS**: Read replicas and connection pooling
- **ElastiCache**: Cluster mode for horizontal scaling
- **Lambda**: Automatic scaling based on demand

## Support and Maintenance

For support and maintenance:

1. **Documentation**: Refer to the comprehensive implementation guide
2. **Monitoring**: Use CloudWatch dashboards and alerts
3. **Updates**: Regular updates for security patches and feature enhancements
4. **Backup**: Regular testing of backup and recovery procedures

## Contributing

When contributing to the infrastructure:

1. Follow Terraform best practices
2. Update documentation for any changes
3. Test changes in development environment first
4. Use proper commit messages and pull request descriptions

## License

This infrastructure code is proprietary to the Multi-Tenant Autonomous Agent Platform project.


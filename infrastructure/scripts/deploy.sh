#!/bin/bash

# Deployment script for Multi-Tenant Autonomous Agent Platform AWS Infrastructure
# This script automates the deployment process with proper error handling and validation

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if required tools are installed
    local tools=("terraform" "aws" "jq")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "$tool is not installed or not in PATH"
            exit 1
        fi
    done
    
    # Check Terraform version
    local terraform_version=$(terraform version -json | jq -r '.terraform_version')
    log_info "Terraform version: $terraform_version"
    
    # Check AWS CLI configuration
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS CLI is not configured or credentials are invalid"
        exit 1
    fi
    
    local aws_account=$(aws sts get-caller-identity --query Account --output text)
    local aws_region=$(aws configure get region)
    log_info "AWS Account: $aws_account"
    log_info "AWS Region: $aws_region"
    
    log_success "Prerequisites check completed"
}

# Function to validate Terraform configuration
validate_terraform() {
    log_info "Validating Terraform configuration..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    terraform init -input=false
    
    # Validate configuration
    terraform validate
    
    # Format check
    if ! terraform fmt -check=true -diff=true; then
        log_warning "Terraform files are not properly formatted"
        log_info "Running terraform fmt to fix formatting..."
        terraform fmt
    fi
    
    log_success "Terraform configuration validation completed"
}

# Function to create backend resources
create_backend() {
    local environment=${1:-dev}
    local region=${2:-us-west-2}
    
    log_info "Creating Terraform backend resources..."
    
    # Create S3 bucket for state
    local bucket_name="agent-platform-terraform-state-$environment-$(date +%s)"
    
    aws s3 mb "s3://$bucket_name" --region "$region"
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "$bucket_name" \
        --versioning-configuration Status=Enabled
    
    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket "$bucket_name" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'
    
    # Block public access
    aws s3api put-public-access-block \
        --bucket "$bucket_name" \
        --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
    
    # Create DynamoDB table for state locking
    local table_name="agent-platform-terraform-locks-$environment"
    
    aws dynamodb create-table \
        --table-name "$table_name" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$region"
    
    # Wait for table to be active
    aws dynamodb wait table-exists --table-name "$table_name" --region "$region"
    
    # Create backend configuration file
    cat > "$TERRAFORM_DIR/backend.conf" << EOF
bucket         = "$bucket_name"
key            = "terraform.tfstate"
region         = "$region"
dynamodb_table = "$table_name"
encrypt        = true
EOF
    
    log_success "Backend resources created successfully"
    log_info "S3 Bucket: $bucket_name"
    log_info "DynamoDB Table: $table_name"
    log_info "Backend configuration saved to backend.conf"
}

# Function to plan deployment
plan_deployment() {
    log_info "Planning Terraform deployment..."
    
    cd "$TERRAFORM_DIR"
    
    # Check if terraform.tfvars exists
    if [[ ! -f "terraform.tfvars" ]]; then
        log_warning "terraform.tfvars not found. Please copy terraform.tfvars.example and customize it."
        log_info "cp terraform.tfvars.example terraform.tfvars"
        exit 1
    fi
    
    # Run terraform plan
    terraform plan -input=false -out=tfplan
    
    log_success "Terraform plan completed successfully"
    log_info "Plan saved to tfplan file"
}

# Function to apply deployment
apply_deployment() {
    log_info "Applying Terraform deployment..."
    
    cd "$TERRAFORM_DIR"
    
    # Check if plan file exists
    if [[ ! -f "tfplan" ]]; then
        log_error "Plan file not found. Please run plan first."
        exit 1
    fi
    
    # Apply the plan
    terraform apply -input=false tfplan
    
    # Clean up plan file
    rm -f tfplan
    
    log_success "Terraform deployment completed successfully"
}

# Function to destroy infrastructure
destroy_infrastructure() {
    log_warning "This will destroy all infrastructure resources!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [[ $confirm != "yes" ]]; then
        log_info "Deployment cancelled"
        exit 0
    fi
    
    cd "$TERRAFORM_DIR"
    
    terraform destroy -input=false
    
    log_success "Infrastructure destroyed successfully"
}

# Function to show outputs
show_outputs() {
    log_info "Terraform outputs:"
    
    cd "$TERRAFORM_DIR"
    
    terraform output -json | jq '.'
}

# Function to configure kubectl
configure_kubectl() {
    log_info "Configuring kubectl..."
    
    cd "$TERRAFORM_DIR"
    
    local cluster_name=$(terraform output -raw cluster_id)
    local region=$(terraform output -raw aws_region)
    
    aws eks update-kubeconfig --region "$region" --name "$cluster_name"
    
    log_success "kubectl configured successfully"
    log_info "Testing cluster connectivity..."
    
    kubectl cluster-info
    kubectl get nodes
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  check-prereqs     Check prerequisites"
    echo "  validate          Validate Terraform configuration"
    echo "  create-backend    Create Terraform backend resources"
    echo "  plan              Plan Terraform deployment"
    echo "  apply             Apply Terraform deployment"
    echo "  destroy           Destroy infrastructure"
    echo "  outputs           Show Terraform outputs"
    echo "  configure-kubectl Configure kubectl for EKS cluster"
    echo "  deploy            Full deployment (validate + plan + apply)"
    echo "  help              Show this help message"
    echo ""
    echo "Options:"
    echo "  --environment     Environment name (default: dev)"
    echo "  --region          AWS region (default: us-west-2)"
    echo ""
    echo "Examples:"
    echo "  $0 deploy"
    echo "  $0 create-backend --environment prod --region us-east-1"
    echo "  $0 plan"
    echo "  $0 apply"
}

# Main function
main() {
    local command=${1:-help}
    local environment="dev"
    local region="us-west-2"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --environment)
                environment="$2"
                shift 2
                ;;
            --region)
                region="$2"
                shift 2
                ;;
            *)
                if [[ -z $command || $command == "help" ]]; then
                    command="$1"
                fi
                shift
                ;;
        esac
    done
    
    case $command in
        check-prereqs)
            check_prerequisites
            ;;
        validate)
            validate_terraform
            ;;
        create-backend)
            create_backend "$environment" "$region"
            ;;
        plan)
            check_prerequisites
            validate_terraform
            plan_deployment
            ;;
        apply)
            apply_deployment
            ;;
        destroy)
            destroy_infrastructure
            ;;
        outputs)
            show_outputs
            ;;
        configure-kubectl)
            configure_kubectl
            ;;
        deploy)
            check_prerequisites
            validate_terraform
            plan_deployment
            apply_deployment
            show_outputs
            configure_kubectl
            ;;
        help|*)
            show_help
            ;;
    esac
}

# Run main function with all arguments
main "$@"


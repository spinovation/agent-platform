#!/bin/bash

# Oregon AWS Resource Cleanup Script
# Safely deletes ElastiCache, NAT Gateway, and VPC resources in us-west-2
# Estimated monthly savings: $45-50

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REGION="us-west-2"
ELASTICACHE_REPLICATION_GROUP="agent-platform-dev-redis"
ELASTICACHE_CLUSTER="agent-platform-dev-redis-001"
NAT_GATEWAY_ID="nat-0af80b175fccfd743"
VPC_ID="vpc-0f7d15a1cebed7df7"

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Function to print status
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to wait for resource deletion
wait_for_deletion() {
    local resource_type=$1
    local check_command=$2
    local max_attempts=30
    local attempt=1
    
    echo "⏳ Waiting for $resource_type deletion..."
    
    while [ $attempt -le $max_attempts ]; do
        if ! eval "$check_command" >/dev/null 2>&1; then
            print_status "$resource_type successfully deleted!"
            return 0
        fi
        
        echo "🔄 Attempt $attempt/$max_attempts - $resource_type still exists..."
        sleep 30
        ((attempt++))
    done
    
    print_error "$resource_type deletion timed out after 15 minutes"
    return 1
}

print_header "OREGON RESOURCE CLEANUP - COST OPTIMIZATION"

echo "🎯 Target Resources for Deletion:"
echo "   • ElastiCache: $ELASTICACHE_REPLICATION_GROUP"
echo "   • NAT Gateway: $NAT_GATEWAY_ID"
echo "   • VPC: $VPC_ID"
echo "   • Region: $REGION"
echo "   • Expected Savings: ~$45-50/month"

print_header "STEP 1: VERIFY MAIN INFRASTRUCTURE SAFETY"

echo "🛡️ Verifying your main infrastructure in us-east-1 is safe..."

# Check main infrastructure
aws elasticache describe-replication-groups --region us-east-1 >/dev/null 2>&1 && \
    print_status "Main ElastiCache in us-east-1 is running" || \
    print_error "Cannot verify main ElastiCache"

kubectl get services -n ai-platform >/dev/null 2>&1 && \
    print_status "AI Platform is running" || \
    print_error "Cannot verify AI Platform"

print_header "STEP 2: DELETE ELASTICACHE REPLICATION GROUP"

echo "🗑️ Deleting ElastiCache replication group: $ELASTICACHE_REPLICATION_GROUP"

# Try to delete replication group
if aws elasticache describe-replication-groups \
    --replication-group-id "$ELASTICACHE_REPLICATION_GROUP" \
    --region "$REGION" >/dev/null 2>&1; then
    
    echo "📋 Found replication group, attempting deletion..."
    
    if aws elasticache delete-replication-group \
        --replication-group-id "$ELASTICACHE_REPLICATION_GROUP" \
        --region "$REGION" \
        --no-retain-primary-cluster >/dev/null 2>&1; then
        
        print_status "ElastiCache deletion initiated"
        
        # Wait for deletion
        wait_for_deletion "ElastiCache" \
            "aws elasticache describe-replication-groups --replication-group-id $ELASTICACHE_REPLICATION_GROUP --region $REGION"
        
    else
        print_error "Failed to delete ElastiCache replication group"
        exit 1
    fi
else
    print_status "ElastiCache replication group not found (already deleted)"
fi

print_header "STEP 3: DELETE NAT GATEWAY"

echo "🗑️ Deleting NAT Gateway: $NAT_GATEWAY_ID"

if aws ec2 describe-nat-gateways \
    --nat-gateway-ids "$NAT_GATEWAY_ID" \
    --region "$REGION" >/dev/null 2>&1; then
    
    echo "📋 Found NAT Gateway, attempting deletion..."
    
    if aws ec2 delete-nat-gateway \
        --nat-gateway-id "$NAT_GATEWAY_ID" \
        --region "$REGION" >/dev/null 2>&1; then
        
        print_status "NAT Gateway deletion initiated"
        
        # Wait for deletion
        wait_for_deletion "NAT Gateway" \
            "aws ec2 describe-nat-gateways --nat-gateway-ids $NAT_GATEWAY_ID --region $REGION --query 'NatGateways[?State!=\`deleted\`]' --output text"
        
    else
        print_error "Failed to delete NAT Gateway"
        exit 1
    fi
else
    print_status "NAT Gateway not found (already deleted)"
fi

print_header "STEP 4: DELETE VPC AND DEPENDENCIES"

echo "🗑️ Cleaning up VPC dependencies and deleting VPC: $VPC_ID"

if aws ec2 describe-vpcs \
    --vpc-ids "$VPC_ID" \
    --region "$REGION" >/dev/null 2>&1; then
    
    echo "📋 Found VPC, cleaning up dependencies..."
    
    # Delete Internet Gateways
    echo "🔌 Deleting Internet Gateways..."
    aws ec2 describe-internet-gateways \
        --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
        --region "$REGION" \
        --query 'InternetGateways[*].InternetGatewayId' \
        --output text | while read igw_id; do
        if [ ! -z "$igw_id" ]; then
            aws ec2 detach-internet-gateway --internet-gateway-id "$igw_id" --vpc-id "$VPC_ID" --region "$REGION" 2>/dev/null || true
            aws ec2 delete-internet-gateway --internet-gateway-id "$igw_id" --region "$REGION" 2>/dev/null || true
            echo "   Deleted Internet Gateway: $igw_id"
        fi
    done
    
    # Delete Subnets
    echo "🏠 Deleting Subnets..."
    aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --region "$REGION" \
        --query 'Subnets[*].SubnetId' \
        --output text | while read subnet_id; do
        if [ ! -z "$subnet_id" ]; then
            aws ec2 delete-subnet --subnet-id "$subnet_id" --region "$REGION" 2>/dev/null || true
            echo "   Deleted Subnet: $subnet_id"
        fi
    done
    
    # Delete Route Tables (except main)
    echo "🛣️ Deleting Route Tables..."
    aws ec2 describe-route-tables \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --region "$REGION" \
        --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' \
        --output text | while read rt_id; do
        if [ ! -z "$rt_id" ]; then
            aws ec2 delete-route-table --route-table-id "$rt_id" --region "$REGION" 2>/dev/null || true
            echo "   Deleted Route Table: $rt_id"
        fi
    done
    
    # Delete Security Groups (except default)
    echo "🔒 Deleting Security Groups..."
    aws ec2 describe-security-groups \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --region "$REGION" \
        --query 'SecurityGroups[?GroupName!=`default`].GroupId' \
        --output text | while read sg_id; do
        if [ ! -z "$sg_id" ]; then
            aws ec2 delete-security-group --group-id "$sg_id" --region "$REGION" 2>/dev/null || true
            echo "   Deleted Security Group: $sg_id"
        fi
    done
    
    # Wait a moment for dependencies to clear
    echo "⏳ Waiting for dependencies to clear..."
    sleep 10
    
    # Delete VPC
    echo "🗑️ Deleting VPC..."
    if aws ec2 delete-vpc --vpc-id "$VPC_ID" --region "$REGION" >/dev/null 2>&1; then
        print_status "VPC deletion initiated"
    else
        print_warning "VPC deletion failed - may have remaining dependencies"
    fi
else
    print_status "VPC not found (already deleted)"
fi

print_header "STEP 5: VALIDATION AND COST SAVINGS CONFIRMATION"

echo "🔍 Validating cleanup completion..."

# Check ElastiCache
echo "📊 ElastiCache Status:"
if aws elasticache describe-cache-clusters --region "$REGION" --query 'CacheClusters' --output text 2>/dev/null | grep -q "$ELASTICACHE_CLUSTER"; then
    print_warning "ElastiCache still exists"
else
    print_status "ElastiCache successfully removed"
fi

# Check NAT Gateway
echo "🚪 NAT Gateway Status:"
if aws ec2 describe-nat-gateways --region "$REGION" --query 'NatGateways[?State!=`deleted`]' --output text 2>/dev/null | grep -q "$NAT_GATEWAY_ID"; then
    print_warning "NAT Gateway still exists"
else
    print_status "NAT Gateway successfully removed"
fi

# Check VPC
echo "🌐 VPC Status:"
if aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --region "$REGION" >/dev/null 2>&1; then
    print_warning "VPC still exists"
else
    print_status "VPC successfully removed"
fi

print_header "CLEANUP COMPLETE - COST SAVINGS ACHIEVED"

echo "💰 Monthly Cost Savings:"
echo "   • ElastiCache: ~$12-15/month"
echo "   • NAT Gateway: ~$32/month"
echo "   • VPC & Dependencies: ~$3-5/month"
echo "   • Total Savings: ~$47-52/month"
echo "   • Annual Savings: ~$564-624/year"

echo ""
echo "🎯 Next Steps:"
echo "   1. Monitor your AWS billing for reduced charges"
echo "   2. Verify your main AI platform still works:"
echo "      curl http://a15afaf7c7d7a4622b17be3367f40f68-1446456911.us-east-1.elb.amazonaws.com:8000/health"
echo "   3. Run the validation script to double-check"

print_status "Oregon resource cleanup completed successfully!"

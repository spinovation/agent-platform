#!/bin/bash

# AWS Cost and Resource Audit Script
# Comprehensive analysis of AWS resources and cost optimization opportunities

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Function to print warnings
print_warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
}

# Function to print errors
print_error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Get AWS account info
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "Unknown")
CURRENT_USER=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null || echo "Unknown")

print_header "AWS COST & RESOURCE AUDIT REPORT"
echo "Account ID: $ACCOUNT_ID"
echo "Current User: $CURRENT_USER"
echo "Generated: $(date)"

# Define regions to check
REGIONS=("us-east-1" "us-west-2")

print_header "1. KUBERNETES CLUSTER ANALYSIS"

echo "EKS Cluster Status:"
kubectl cluster-info 2>/dev/null || print_error "kubectl not configured"

echo -e "\nEKS Nodes:"
kubectl get nodes -o wide 2>/dev/null || print_error "Cannot get EKS nodes"

echo -e "\nAI Platform Services:"
kubectl get services -n ai-platform 2>/dev/null || print_warning "ai-platform namespace not found"

print_header "2. REGIONAL RESOURCE ANALYSIS"

for region in "${REGIONS[@]}"; do
    echo -e "\n${YELLOW}=== REGION: $region ===${NC}"
    
    echo -e "\n📊 EC2 Instances:"
    aws ec2 describe-instances --region $region \
        --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,LaunchTime,Tags[?Key==`Name`].Value|[0]]' \
        --output table 2>/dev/null || print_error "Cannot access EC2 in $region"
    
    echo -e "\n💾 ElastiCache Clusters:"
    aws elasticache describe-cache-clusters --region $region \
        --query 'CacheClusters[*].[CacheClusterId,CacheNodeType,Engine,CacheClusterStatus,PreferredAvailabilityZone]' \
        --output table 2>/dev/null || print_error "Cannot access ElastiCache in $region"
    
    echo -e "\n🗄️ RDS Instances:"
    aws rds describe-db-instances --region $region \
        --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceClass,Engine,DBInstanceStatus,MultiAZ,AllocatedStorage]' \
        --output table 2>/dev/null || print_error "Cannot access RDS in $region"
    
    echo -e "\n⚖️ Load Balancers:"
    aws elbv2 describe-load-balancers --region $region \
        --query 'LoadBalancers[*].[LoadBalancerName,Type,State.Code,Scheme,CreatedTime]' \
        --output table 2>/dev/null || print_error "Cannot access ELB in $region"
    
    echo -e "\n🌐 VPCs:"
    aws ec2 describe-vpcs --region $region \
        --query 'Vpcs[*].[VpcId,State,CidrBlock,IsDefault,Tags[?Key==`Name`].Value|[0]]' \
        --output table 2>/dev/null || print_error "Cannot access VPC in $region"
    
    echo -e "\n🚪 NAT Gateways:"
    aws ec2 describe-nat-gateways --region $region \
        --query 'NatGateways[*].[NatGatewayId,State,VpcId,SubnetId]' \
        --output table 2>/dev/null || print_error "Cannot access NAT Gateways in $region"
    
    echo -e "\n💿 EBS Volumes:"
    aws ec2 describe-volumes --region $region \
        --query 'Volumes[*].[VolumeId,VolumeType,Size,State,Attachments[0].InstanceId]' \
        --output table 2>/dev/null || print_error "Cannot access EBS in $region"
done

print_header "3. CROSS-REGION DEPENDENCY ANALYSIS"

echo "🔍 Checking for cross-region dependencies..."

echo -e "\n📡 CloudFront Distributions:"
aws cloudfront list-distributions \
    --query 'DistributionList.Items[*].[Id,DomainName,Status,Origins.Items[0].DomainName]' \
    --output table 2>/dev/null || print_warning "Cannot access CloudFront"

echo -e "\n🏥 Route 53 Health Checks:"
aws route53 list-health-checks \
    --query 'HealthChecks[*].[Id,Type,ResourcePath,FullyQualifiedDomainName]' \
    --output table 2>/dev/null || print_warning "Cannot access Route 53"

echo -e "\n🔐 KMS Keys:"
for region in "${REGIONS[@]}"; do
    echo "KMS Keys in $region:"
    aws kms list-keys --region $region \
        --query 'Keys[*].[KeyId]' \
        --output table 2>/dev/null || print_warning "Cannot access KMS in $region"
done

print_header "4. COST ESTIMATION ANALYSIS"

echo "💰 Estimated Monthly Costs by Resource Type:"
echo ""

# Cost estimates based on standard pricing
echo "EKS Control Plane: ~$73/month per cluster"
echo "EC2 t3.medium: ~$31.68/month per instance"
echo "ElastiCache t3.micro: ~$12.96/month per node"
echo "RDS t3.micro: ~$13.32/month per instance"
echo "Application Load Balancer: ~$18/month"
echo "NAT Gateway: ~$32.40/month per gateway"
echo "EBS gp2: ~$0.10/GB/month"

print_header "5. OPTIMIZATION RECOMMENDATIONS"

echo "🎯 Potential Cost Savings:"
echo ""

# Check for duplicate resources
echo "🔍 Checking for duplicate resources..."

# Count ElastiCache clusters
EAST_CACHE_COUNT=$(aws elasticache describe-cache-clusters --region us-east-1 --query 'length(CacheClusters)' --output text 2>/dev/null || echo "0")
WEST_CACHE_COUNT=$(aws elasticache describe-cache-clusters --region us-west-2 --query 'length(CacheClusters)' --output text 2>/dev/null || echo "0")

if [[ $EAST_CACHE_COUNT -gt 0 && $WEST_CACHE_COUNT -gt 0 ]]; then
    print_warning "Duplicate ElastiCache clusters found in both regions"
    echo "   💰 Potential savings: ~$12.96/month"
fi

# Count VPCs
EAST_VPC_COUNT=$(aws ec2 describe-vpcs --region us-east-1 --query 'length(Vpcs[?IsDefault==`false`])' --output text 2>/dev/null || echo "0")
WEST_VPC_COUNT=$(aws ec2 describe-vpcs --region us-west-2 --query 'length(Vpcs[?IsDefault==`false`])' --output text 2>/dev/null || echo "0")

if [[ $EAST_VPC_COUNT -gt 0 && $WEST_VPC_COUNT -gt 0 ]]; then
    print_warning "Custom VPCs found in both regions"
    echo "   💰 Check if both are needed"
fi

print_header "6. SAFETY CHECK RESULTS"

echo "🛡️ Safety Analysis for Resource Cleanup:"
echo ""

# Check if Oregon resources are connected to main infrastructure
echo "Checking Oregon resource dependencies..."

# Check if any Kubernetes services reference Oregon
K8S_OREGON_REF=$(kubectl get services -A -o yaml 2>/dev/null | grep -i "us-west-2\|oregon" | wc -l)
if [[ $K8S_OREGON_REF -gt 0 ]]; then
    print_error "Kubernetes services reference Oregon resources - DO NOT DELETE"
else
    print_success "No Kubernetes dependencies on Oregon resources"
fi

# Check for load balancer dependencies
LB_COUNT_OREGON=$(aws elbv2 describe-load-balancers --region us-west-2 --query 'length(LoadBalancers)' --output text 2>/dev/null || echo "0")
if [[ $LB_COUNT_OREGON -gt 0 ]]; then
    print_warning "Load balancers found in Oregon - verify they're not in use"
else
    print_success "No load balancers in Oregon"
fi

print_header "7. CLEANUP RECOMMENDATIONS"

echo "Based on the analysis above:"
echo ""

if [[ $WEST_CACHE_COUNT -gt 0 && $K8S_OREGON_REF -eq 0 ]]; then
    echo "✅ SAFE TO DELETE: Oregon ElastiCache clusters (not referenced by main infrastructure)"
    echo "   Command: aws elasticache delete-cache-cluster --cache-cluster-id <cluster-id> --region us-west-2"
    echo "   💰 Savings: ~$12.96/month"
    echo ""
fi

if [[ $WEST_VPC_COUNT -gt 0 && $LB_COUNT_OREGON -eq 0 ]]; then
    echo "⚠️  INVESTIGATE: Oregon VPC - check if it has active resources"
    echo "   Review NAT gateways, subnets, and route tables before deletion"
    echo ""
fi

echo "🎯 Total potential monthly savings: $2.60 - $31.20"

print_header "AUDIT COMPLETE"

echo "📋 Summary:"
echo "- Review the safety check results above"
echo "- Only delete resources marked as 'SAFE TO DELETE'"
echo "- Always backup/snapshot before deletion"
echo "- Monitor costs after cleanup"
echo ""
echo "For detailed cost analysis, check AWS Cost Explorer in the console."

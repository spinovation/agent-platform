# Outputs for Multi-Tenant Autonomous Agent Platform AWS Infrastructure

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "nat_gateway_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = module.vpc.natgw_ids
}

# EKS Outputs
output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = module.eks.cluster_iam_role_name
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN associated with EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_primary_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster"
  value       = module.eks.cluster_primary_security_group_id
}

output "node_security_group_id" {
  description = "ID of the node shared security group"
  value       = module.eks.node_security_group_id
}

output "node_security_group_arn" {
  description = "Amazon Resource Name (ARN) of the node shared security group"
  value       = module.eks.node_security_group_arn
}

# EKS Node Groups
output "eks_managed_node_groups" {
  description = "Map of attribute maps for all EKS managed node groups created"
  value       = module.eks.eks_managed_node_groups
}

output "eks_managed_node_groups_autoscaling_group_names" {
  description = "List of the autoscaling group names created by EKS managed node groups"
  value       = module.eks.eks_managed_node_groups_autoscaling_group_names
}

# RDS Outputs
output "rds_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

output "rds_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.main.arn
}

output "rds_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_instance_hosted_zone_id" {
  description = "RDS instance hosted zone ID"
  value       = aws_db_instance.main.hosted_zone_id
}

output "rds_instance_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "rds_instance_name" {
  description = "RDS instance name"
  value       = aws_db_instance.main.db_name
}

output "rds_instance_username" {
  description = "RDS instance root username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "rds_instance_password" {
  description = "RDS instance master password"
  value       = random_password.rds_password.result
  sensitive   = true
}

output "rds_subnet_group_id" {
  description = "ID of the RDS subnet group"
  value       = module.vpc.database_subnet_group_name
}

output "rds_subnet_group_arn" {
  description = "ARN of the RDS subnet group"
  value       = "arn:aws:rds:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subgrp:${module.vpc.database_subnet_group_name}"
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

# ElastiCache Outputs
output "elasticache_replication_group_id" {
  description = "ElastiCache replication group ID"
  value       = aws_elasticache_replication_group.main.id
}

output "elasticache_replication_group_arn" {
  description = "ElastiCache replication group ARN"
  value       = aws_elasticache_replication_group.main.arn
}

output "elasticache_primary_endpoint_address" {
  description = "ElastiCache primary endpoint address"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "elasticache_reader_endpoint_address" {
  description = "ElastiCache reader endpoint address"
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

output "elasticache_port" {
  description = "ElastiCache port"
  value       = aws_elasticache_replication_group.main.port
}

output "elasticache_auth_token" {
  description = "ElastiCache auth token"
  value       = random_password.redis_auth_token.result
  sensitive   = true
}

output "elasticache_subnet_group_name" {
  description = "ElastiCache subnet group name"
  value       = aws_elasticache_subnet_group.main.name
}

output "elasticache_security_group_id" {
  description = "ElastiCache security group ID"
  value       = aws_security_group.elasticache.id
}

# Security Group Outputs
output "eks_remote_access_security_group_id" {
  description = "EKS remote access security group ID"
  value       = aws_security_group.eks_remote_access.id
}

# IAM Outputs
output "rds_enhanced_monitoring_iam_role_name" {
  description = "RDS enhanced monitoring IAM role name"
  value       = aws_iam_role.rds_enhanced_monitoring.name
}

output "rds_enhanced_monitoring_iam_role_arn" {
  description = "RDS enhanced monitoring IAM role ARN"
  value       = aws_iam_role.rds_enhanced_monitoring.arn
}

# AWS Account Information
output "aws_caller_identity_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_caller_identity_arn" {
  description = "AWS caller identity ARN"
  value       = data.aws_caller_identity.current.arn
}

output "aws_caller_identity_user_id" {
  description = "AWS caller identity user ID"
  value       = data.aws_caller_identity.current.user_id
}

# Region and Availability Zones
output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "availability_zones" {
  description = "List of availability zones"
  value       = data.aws_availability_zones.available.names
}

# Kubectl Configuration Command
#output "configure_kubectl" {
# description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
#  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_id}"
#}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region us-east-1 update-kubeconfig --name agent-platform-dev-eks"
}
# Connection Information
output "connection_info" {
  description = "Connection information for services"
  value = {
    eks_cluster_name = module.eks.cluster_id
    eks_endpoint     = module.eks.cluster_endpoint
    rds_endpoint     = aws_db_instance.main.endpoint
    rds_port         = aws_db_instance.main.port
    rds_database     = aws_db_instance.main.db_name
    redis_endpoint   = aws_elasticache_replication_group.main.primary_endpoint_address
    redis_port       = aws_elasticache_replication_group.main.port
  }
  sensitive = false
}

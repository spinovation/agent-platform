# Variables for Multi-Tenant Autonomous Agent Platform AWS Infrastructure

# General Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "agent-platform"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner of the infrastructure"
  type        = string
  default     = "platform-team"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets"
  type        = bool
  default     = false
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed for remote access"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

# EKS Configuration
variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "eks_node_instance_types" {
  description = "Instance types for EKS general node group"
  type        = list(string)
  default     = ["t3.medium", "t3.large"]
}

variable "eks_compute_node_instance_types" {
  description = "Instance types for EKS compute node group"
  type        = list(string)
  default     = ["c5.large", "c5.xlarge"]
}

variable "eks_node_group_min_size" {
  description = "Minimum size of the EKS node group"
  type        = number
  default     = 1
}

variable "eks_node_group_max_size" {
  description = "Maximum size of the EKS node group"
  type        = number
  default     = 10
}

variable "eks_node_group_desired_size" {
  description = "Desired size of the EKS node group"
  type        = number
  default     = 3
}

variable "ec2_key_pair_name" {
  description = "Name of the EC2 key pair for EKS node access"
  type        = string
  default     = ""
}

# RDS Configuration
variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15.4"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "rds_allocated_storage" {
  description = "Initial allocated storage for RDS instance (GB)"
  type        = number
  default     = 100
}

variable "rds_max_allocated_storage" {
  description = "Maximum allocated storage for RDS instance (GB)"
  type        = number
  default     = 1000
}

variable "database_name" {
  description = "Name of the initial database"
  type        = string
  default     = "agentplatform"
}

variable "database_username" {
  description = "Username for the database"
  type        = string
  default     = "dbadmin"
}

variable "rds_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "rds_backup_window" {
  description = "Backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "rds_maintenance_window" {
  description = "Maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = true
}

variable "rds_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

# ElastiCache Configuration
variable "elasticache_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.medium"
}

variable "elasticache_num_cache_nodes" {
  description = "Number of cache nodes"
  type        = number
  default     = 2
}

variable "elasticache_snapshot_retention_limit" {
  description = "Number of days to retain snapshots"
  type        = number
  default     = 5
}

variable "elasticache_snapshot_window" {
  description = "Daily time range for snapshots"
  type        = string
  default     = "03:00-05:00"
}

variable "elasticache_maintenance_window" {
  description = "Weekly time range for maintenance"
  type        = string
  default     = "sun:05:00-sun:07:00"
}

variable "elasticache_automatic_failover_enabled" {
  description = "Enable automatic failover"
  type        = bool
  default     = true
}

# Lambda Configuration
variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.11"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 300
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512
}

# Monitoring Configuration
variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs"
  type        = bool
  default     = true
}

variable "log_retention_in_days" {
  description = "CloudWatch logs retention period in days"
  type        = number
  default     = 30
}

# Security Configuration
variable "enable_waf" {
  description = "Enable AWS WAF"
  type        = bool
  default     = true
}

variable "enable_shield" {
  description = "Enable AWS Shield Advanced"
  type        = bool
  default     = false
}

# Cost Optimization
variable "enable_spot_instances" {
  description = "Enable spot instances for EKS node groups"
  type        = bool
  default     = false
}

variable "spot_instance_types" {
  description = "Instance types for spot instances"
  type        = list(string)
  default     = ["t3.medium", "t3.large", "m5.large", "m5.xlarge"]
}

# Backup and Disaster Recovery
variable "enable_cross_region_backup" {
  description = "Enable cross-region backup"
  type        = bool
  default     = false
}

variable "backup_region" {
  description = "Region for cross-region backups"
  type        = string
  default     = "us-east-1"
}

# Compliance and Governance
variable "enable_config" {
  description = "Enable AWS Config"
  type        = bool
  default     = true
}

variable "enable_cloudtrail" {
  description = "Enable AWS CloudTrail"
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Enable AWS GuardDuty"
  type        = bool
  default     = true
}

# Tagging
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}


# Secrets Management for Multi-Tenant Autonomous Agent Platform

# KMS Key for encryption
resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.project_name} ${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key for RDS"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key for ElastiCache"
        Effect = "Allow"
        Principal = {
          Service = "elasticache.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key for Lambda"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-kms-key"
  })
}

# KMS Key Alias
resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-${var.environment}"
  target_key_id = aws_kms_key.main.key_id
}

# Secrets Manager secret for RDS credentials
resource "aws_secretsmanager_secret" "rds_credentials" {
  name                    = "${var.project_name}-${var.environment}-rds-credentials"
  description             = "RDS credentials for ${var.project_name} ${var.environment}"
  kms_key_id              = aws_kms_key.main.arn
  recovery_window_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-rds-credentials"
  })
}

# Secrets Manager secret version for RDS credentials
resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = aws_db_instance.main.username
    password = random_password.rds_password.result
    engine   = "postgres"
    host     = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
    dbname   = aws_db_instance.main.db_name
  })
}

# Secrets Manager secret for Redis auth token
resource "aws_secretsmanager_secret" "redis_credentials" {
  name                    = "${var.project_name}-${var.environment}-redis-credentials"
  description             = "Redis credentials for ${var.project_name} ${var.environment}"
  kms_key_id              = aws_kms_key.main.arn
  recovery_window_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-redis-credentials"
  })
}

# Secrets Manager secret version for Redis credentials
resource "aws_secretsmanager_secret_version" "redis_credentials" {
  secret_id = aws_secretsmanager_secret.redis_credentials.id
  secret_string = jsonencode({
    auth_token = random_password.redis_auth_token.result
    host       = aws_elasticache_replication_group.main.primary_endpoint_address
    port       = aws_elasticache_replication_group.main.port
  })
}

# Secrets Manager secret for application configuration
resource "aws_secretsmanager_secret" "app_config" {
  name                    = "${var.project_name}-${var.environment}-app-config"
  description             = "Application configuration for ${var.project_name} ${var.environment}"
  kms_key_id              = aws_kms_key.main.arn
  recovery_window_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-app-config"
  })
}

# Generate JWT secret
resource "random_password" "jwt_secret" {
  length  = 64
  special = true
}

# Generate API key
resource "random_password" "api_key" {
  length  = 32
  special = false
}

# Secrets Manager secret version for application configuration
resource "aws_secretsmanager_secret_version" "app_config" {
  secret_id = aws_secretsmanager_secret.app_config.id
  secret_string = jsonencode({
    jwt_secret = random_password.jwt_secret.result
    api_key    = random_password.api_key.result
    environment = var.environment
    region     = var.aws_region
  })
}

# IAM policy for accessing secrets
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.project_name}-${var.environment}-secrets-access"
  description = "Policy for accessing secrets in ${var.project_name} ${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.rds_credentials.arn,
          aws_secretsmanager_secret.redis_credentials.arn,
          aws_secretsmanager_secret.app_config.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.main.arn
      }
    ]
  })

  tags = local.common_tags
}

# IAM role for EKS service account to access secrets
resource "aws_iam_role" "eks_secrets_access" {
  name = "${var.project_name}-${var.environment}-eks-secrets-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:default:secrets-access"
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

# Attach secrets access policy to EKS role
resource "aws_iam_role_policy_attachment" "eks_secrets_access" {
  role       = aws_iam_role.eks_secrets_access.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

# Parameter Store parameters for non-sensitive configuration
resource "aws_ssm_parameter" "cluster_name" {
  name  = "/${var.project_name}/${var.environment}/cluster_name"
  type  = "String"
  value = module.eks.cluster_id

  tags = local.common_tags
}

resource "aws_ssm_parameter" "vpc_id" {
  name  = "/${var.project_name}/${var.environment}/vpc_id"
  type  = "String"
  value = module.vpc.vpc_id

  tags = local.common_tags
}

resource "aws_ssm_parameter" "private_subnets" {
  name  = "/${var.project_name}/${var.environment}/private_subnets"
  type  = "StringList"
  value = join(",", module.vpc.private_subnets)

  tags = local.common_tags
}

resource "aws_ssm_parameter" "public_subnets" {
  name  = "/${var.project_name}/${var.environment}/public_subnets"
  type  = "StringList"
  value = join(",", module.vpc.public_subnets)

  tags = local.common_tags
}

resource "aws_ssm_parameter" "database_subnets" {
  name  = "/${var.project_name}/${var.environment}/database_subnets"
  type  = "StringList"
  value = join(",", module.vpc.database_subnets)

  tags = local.common_tags
}

# IAM policy for accessing Parameter Store
resource "aws_iam_policy" "parameter_store_access" {
  name        = "${var.project_name}-${var.environment}-parameter-store-access"
  description = "Policy for accessing Parameter Store in ${var.project_name} ${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/${var.environment}/*"
      }
    ]
  })

  tags = local.common_tags
}

# Attach Parameter Store access policy to EKS role
resource "aws_iam_role_policy_attachment" "eks_parameter_store_access" {
  role       = aws_iam_role.eks_secrets_access.name
  policy_arn = aws_iam_policy.parameter_store_access.arn
}


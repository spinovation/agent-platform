# Lambda Functions for Multi-Tenant Autonomous Agent Platform

# Lambda execution role
# resource "aws_iam_role" "lambda_execution_role" {
#   name = "${var.project_name}-${var.environment}-lambda-execution-role"
#
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "lambda.amazonaws.com"
#         }
#       }
#     ]
#   })
#
#   tags = local.common_tags
# }

# Lambda basic execution policy attachment
# resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
#   role       = aws_iam_role.lambda_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }

# Lambda VPC execution policy attachment
# resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
#   role       = aws_iam_role.lambda_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
# }

# Custom policy for Lambda functions
# resource "aws_iam_role_policy" "lambda_custom_policy" {
#   name = "${var.project_name}-${var.environment}-lambda-custom-policy"
#   role = aws_iam_role.lambda_execution_role.id
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "rds:DescribeDBInstances",
#           "rds:DescribeDBClusters",
#           "elasticache:DescribeReplicationGroups",
#           "elasticache:DescribeCacheClusters",
#           "eks:DescribeCluster",
#           "eks:ListClusters",
#           "secretsmanager:GetSecretValue",
#           "secretsmanager:DescribeSecret",
#           "kms:Decrypt",
#           "kms:GenerateDataKey"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents"
#         ]
#         Resource = "arn:aws:logs:*:*:*"
#       }
#     ]
#   })
# }

# Security group for Lambda functions
# resource "aws_security_group" "lambda" {
#   name_prefix = "${var.project_name}-${var.environment}-lambda"
#   vpc_id      = module.vpc.vpc_id
#
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   # Allow access to RDS
#   egress {
#     from_port       = 5432
#     to_port         = 5432
#     protocol        = "tcp"
#     security_groups = [aws_security_group.rds.id]
#   }
#
#   # Allow access to ElastiCache
#   egress {
#     from_port       = 6379
#     to_port         = 6379
#     protocol        = "tcp"
#     security_groups = [aws_security_group.elasticache.id]
#   }
#
#   tags = merge(local.common_tags, {
#     Name = "${var.project_name}-${var.environment}-lambda"
#   })
# }

# Lambda layer for common dependencies
# resource "aws_lambda_layer_version" "common_dependencies" {
#   filename         = "${path.module}/../lambda-layers/common-dependencies.zip"
#   layer_name       = "${var.project_name}-${var.environment}-common-dependencies"
#   source_code_hash = filebase64sha256("${path.module}/../lambda-layers/common-dependencies.zip")
#
#   compatible_runtimes = [var.lambda_runtime]
#   description         = "Common dependencies for agent platform Lambda functions"
#
#   depends_on = [null_resource.build_lambda_layer]
# }

# Build Lambda layer
# resource "null_resource" "build_lambda_layer" {
#   triggers = {
#     requirements = filemd5("${path.module}/../lambda-layers/requirements.txt")
#   }
#
#   provisioner "local-exec" {
#     command = <<-EOT
#       cd ${path.module}/../lambda-layers
#       mkdir -p python/lib/python3.11/site-packages
#       pip install -r requirements.txt -t python/lib/python3.11/site-packages/
#       zip -r common-dependencies.zip python/
#       rm -rf python/
#     EOT
#   }
# }

# Health Check Lambda Function
# resource "aws_lambda_function" "health_check" {
#   filename         = "${path.module}/../lambda-functions/health-check.zip"
#   function_name    = "${var.project_name}-${var.environment}-health-check"
#   role            = aws_iam_role.lambda_execution_role.arn
#   handler         = "index.handler"
#   source_code_hash = filebase64sha256("${path.module}/../lambda-functions/health-check.zip")
#   runtime         = var.lambda_runtime
#   timeout         = var.lambda_timeout
#   memory_size     = var.lambda_memory_size
#   vpc_config {
#     subnet_ids         = module.vpc.private_subnets
#     security_group_ids = [aws_security_group.lambda.id]
#   }
#
#   layers = [aws_lambda_layer_version.common_dependencies.arn]
#
#   environment {
#     variables = {
#       RDS_ENDPOINT    = aws_db_instance.main.endpoint
#       RDS_PORT        = aws_db_instance.main.port
#       RDS_DATABASE    = aws_db_instance.main.db_name
#       REDIS_ENDPOINT  = aws_elasticache_replication_group.main.primary_endpoint_address
#       REDIS_PORT      = aws_elasticache_replication_group.main.port
#       EKS_CLUSTER     = module.eks.cluster_id
#       ENVIRONMENT     = var.environment
#     }
#   }
#
#   depends_on = [
#     aws_iam_role_policy_attachment.lambda_basic_execution,
#     aws_iam_role_policy_attachment.lambda_vpc_execution,
#     aws_cloudwatch_log_group.health_check_logs,
#     null_resource.build_health_check_function
#   ]
#
#   tags = local.common_tags
# }

# Build Health Check Lambda function
# resource "null_resource" "build_health_check_function" {
#   triggers = {
#     source_code = filemd5("${path.module}/../lambda-functions/health-check/index.py")
#   }
#
#   provisioner "local-exec" {
#     command = <<-EOT
#       cd ${path.module}/../lambda-functions/health-check
#       zip -r ../health-check.zip .
#     EOT
#   }
# }

# CloudWatch Log Group for Health Check Lambda
# resource "aws_cloudwatch_log_group" "health_check_logs" {
#   name              = "/aws/lambda/${var.project_name}-${var.environment}-health-check"
#   retention_in_days = var.log_retention_in_days
#
#   tags = local.common_tags
# }

# Tenant Management Lambda Function
# resource "aws_lambda_function" "tenant_management" {
#   filename         = "${path.module}/../lambda-functions/tenant-management.zip"
#   function_name    = "${var.project_name}-${var.environment}-tenant-management"
#   role            = aws_iam_role.lambda_execution_role.arn
#   handler         = "index.handler"
#   source_code_hash = filebase64sha256("${path.module}/../lambda-functions/tenant-management.zip")
#   runtime         = var.lambda_runtime
#   timeout         = var.lambda_timeout
#   memory_size     = var.lambda_memory_size
#
#   vpc_config {
#     subnet_ids         = module.vpc.private_subnets
#     security_group_ids = [aws_security_group.lambda.id]
#   }
#
#   layers = [aws_lambda_layer_version.common_dependencies.arn]
#
#   environment {
#     variables = {
#       RDS_ENDPOINT    = aws_db_instance.main.endpoint
#       RDS_PORT        = aws_db_instance.main.port
#       RDS_DATABASE    = aws_db_instance.main.db_name
#       RDS_USERNAME    = aws_db_instance.main.username
#       REDIS_ENDPOINT  = aws_elasticache_replication_group.main.primary_endpoint_address
#       REDIS_PORT      = aws_elasticache_replication_group.main.port
#       EKS_CLUSTER     = module.eks.cluster_id
#       ENVIRONMENT     = var.environment
#       SECRET_ARN      = aws_secretsmanager_secret.rds_credentials.arn
#     }
#   }
#
#   depends_on = [
#     aws_iam_role_policy_attachment.lambda_basic_execution,
#     aws_iam_role_policy_attachment.lambda_vpc_execution,
#     aws_cloudwatch_log_group.tenant_management_logs,
#     null_resource.build_tenant_management_function
#   ]
#
#   tags = local.common_tags
# }

# Build Tenant Management Lambda function
# resource "null_resource" "build_tenant_management_function" {
#   triggers = {
#     source_code = filemd5("${path.module}/../lambda-functions/tenant-management/index.py")
#   }
#
#   provisioner "local-exec" {
#     command = <<-EOT
#       cd ${path.module}/../lambda-functions/tenant-management
#       zip -r ../tenant-management.zip .
#     EOT
#   }
# }

# CloudWatch Log Group for Tenant Management Lambda
# resource "aws_cloudwatch_log_group" "tenant_management_logs" {
#   name              = "/aws/lambda/${var.project_name}-${var.environment}-tenant-management"
#   retention_in_days = var.log_retention_in_days
#
#   tags = local.common_tags
# }

# Agent Orchestration Lambda Function
# resource "aws_lambda_function" "agent_orchestration" {
#   filename         = "${path.module}/../lambda-functions/agent-orchestration.zip"
#   function_name    = "${var.project_name}-${var.environment}-agent-orchestration"
#   role            = aws_iam_role.lambda_execution_role.arn
#   handler         = "index.handler"
#   source_code_hash = filebase64sha256("${path.module}/../lambda-functions/agent-orchestration.zip")
#   runtime         = var.lambda_runtime
#   timeout         = var.lambda_timeout
#   memory_size     = var.lambda_memory_size
#
#   vpc_config {
#     subnet_ids         = module.vpc.private_subnets
#     security_group_ids = [aws_security_group.lambda.id]
#   }
#
#   layers = [aws_lambda_layer_version.common_dependencies.arn]
#
#   environment {
#     variables = {
#       RDS_ENDPOINT    = aws_db_instance.main.endpoint
#       RDS_PORT        = aws_db_instance.main.port
#       RDS_DATABASE    = aws_db_instance.main.db_name
#       RDS_USERNAME    = aws_db_instance.main.username
#       REDIS_ENDPOINT  = aws_elasticache_replication_group.main.primary_endpoint_address
#       REDIS_PORT      = aws_elasticache_replication_group.main.port
#       EKS_CLUSTER     = module.eks.cluster_id
#       ENVIRONMENT     = var.environment
#       SECRET_ARN      = aws_secretsmanager_secret.rds_credentials.arn
#     }
#   }
#
#   depends_on = [
#     aws_iam_role_policy_attachment.lambda_basic_execution,
#     aws_iam_role_policy_attachment.lambda_vpc_execution,
#     aws_cloudwatch_log_group.agent_orchestration_logs,
#     null_resource.build_agent_orchestration_function
#   ]
#
#   tags = local.common_tags
# }

# Build Agent Orchestration Lambda function
# resource "null_resource" "build_agent_orchestration_function" {
#   triggers = {
#     source_code = filemd5("${path.module}/../lambda-functions/agent-orchestration/index.py")
#   }
#
#   provisioner "local-exec" {
#     command = <<-EOT
#       cd ${path.module}/../lambda-functions/agent-orchestration
#       zip -r ../agent-orchestration.zip .
#     EOT
#   }
# }

# CloudWatch Log Group for Agent Orchestration Lambda
# resource "aws_cloudwatch_log_group" "agent_orchestration_logs" {
#   name              = "/aws/lambda/${var.project_name}-${var.environment}-agent-orchestration"
#   retention_in_days = var.log_retention_in_days
#
#   tags = local.common_tags
# }

# API Gateway for Lambda functions
# resource "aws_api_gateway_rest_api" "main" {
#   name        = "${var.project_name}-${var.environment}-api"
#   description = "API Gateway for Agent Platform Lambda functions"
#
#   endpoint_configuration {
#     types = ["REGIONAL"]
#   }
#
#   tags = local.common_tags
# }

# API Gateway deployment
# resource "aws_api_gateway_deployment" "main" {
#   depends_on = [
#     aws_api_gateway_integration.health_check,
#     aws_api_gateway_integration.tenant_management,
#     aws_api_gateway_integration.agent_orchestration
#   ]
#
#   rest_api_id = aws_api_gateway_rest_api.main.id
#   stage_name  = var.environment
#
#   lifecycle {
#     create_before_destroy = true
#   }
# }

# Health Check API Gateway resources
# resource "aws_api_gateway_resource" "health" {
#   rest_api_id = aws_api_gateway_rest_api.main.id
#   parent_id   = aws_api_gateway_rest_api.main.root_resource_id
#   path_part   = "health"
# }
#
# resource "aws_api_gateway_method" "health_check" {
#   rest_api_id   = aws_api_gateway_rest_api.main.id
#   resource_id   = aws_api_gateway_resource.health.id
#   http_method   = "GET"
#   authorization = "NONE"
# }
#
# resource "aws_api_gateway_integration" "health_check" {
#   rest_api_id = aws_api_gateway_rest_api.main.id
#   resource_id = aws_api_gateway_resource.health.id
#   http_method = aws_api_gateway_method.health_check.http_method
#
#   integration_http_method = "POST"
#   type                   = "AWS_PROXY"
#   uri                    = aws_lambda_function.health_check.invoke_arn
# }
#
# Lambda permission for API Gateway
# resource "aws_lambda_permission" "health_check_api_gateway" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.health_check.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
# }

# Tenant Management API Gateway resources
# resource "aws_api_gateway_resource" "tenants" {
#   rest_api_id = aws_api_gateway_rest_api.main.id
#   parent_id   = aws_api_gateway_rest_api.main.root_resource_id
#   path_part   = "tenants"
# }
#
# resource "aws_api_gateway_method" "tenant_management" {
#   rest_api_id   = aws_api_gateway_rest_api.main.id
#   resource_id   = aws_api_gateway_resource.tenants.id
#   http_method   = "ANY"
#   authorization = "AWS_IAM"
# }
#
# resource "aws_api_gateway_integration" "tenant_management" {
#   rest_api_id = aws_api_gateway_rest_api.main.id
#   resource_id = aws_api_gateway_resource.tenants.id
#   http_method = aws_api_gateway_method.tenant_management.http_method
#
#   integration_http_method = "POST"
#   type                   = "AWS_PROXY"
#   uri                    = aws_lambda_function.tenant_management.invoke_arn
# }
#
# resource "aws_lambda_permission" "tenant_management_api_gateway" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.tenant_management.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
# }

# Agent Orchestration API Gateway resources
# resource "aws_api_gateway_resource" "agents" {
#   rest_api_id = aws_api_gateway_rest_api.main.id
#   parent_id   = aws_api_gateway_rest_api.main.root_resource_id
#   path_part   = "agents"
# }
#
# resource "aws_api_gateway_method" "agent_orchestration" {
#   rest_api_id   = aws_api_gateway_rest_api.main.id
#   resource_id   = aws_api_gateway_resource.agents.id
#   http_method   = "ANY"
#   authorization = "AWS_IAM"
# }
#
# resource "aws_api_gateway_integration" "agent_orchestration" {
#   rest_api_id = aws_api_gateway_rest_api.main.id
#   resource_id = aws_api_gateway_resource.agents.id
#   http_method = aws_api_gateway_method.agent_orchestration.http_method
#
#   integration_http_method = "POST"
#   type                   = "AWS_PROXY"
#   uri                    = aws_lambda_function.agent_orchestration.invoke_arn
# }
#
# resource "aws_lambda_permission" "agent_orchestration_api_gateway" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.agent_orchestration.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
# }

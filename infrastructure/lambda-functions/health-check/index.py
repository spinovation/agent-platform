"""
Health Check Lambda Function for Multi-Tenant Autonomous Agent Platform
Provides comprehensive health checks for all infrastructure components
"""

import json
import os
import boto3
import psycopg2
import redis
from datetime import datetime
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Main Lambda handler for health check functionality
    """
    try:
        # Initialize health check results
        health_status = {
            'timestamp': datetime.utcnow().isoformat(),
            'overall_status': 'healthy',
            'components': {}
        }
        
        # Check RDS connectivity
        rds_status = check_rds_health()
        health_status['components']['rds'] = rds_status
        
        # Check Redis connectivity
        redis_status = check_redis_health()
        health_status['components']['redis'] = redis_status
        
        # Check EKS cluster status
        eks_status = check_eks_health()
        health_status['components']['eks'] = eks_status
        
        # Check AWS services
        aws_status = check_aws_services()
        health_status['components']['aws_services'] = aws_status
        
        # Determine overall status
        component_statuses = [
            rds_status['status'],
            redis_status['status'],
            eks_status['status'],
            aws_status['status']
        ]
        
        if 'unhealthy' in component_statuses:
            health_status['overall_status'] = 'unhealthy'
        elif 'degraded' in component_statuses:
            health_status['overall_status'] = 'degraded'
        
        # Return response
        return {
            'statusCode': 200 if health_status['overall_status'] == 'healthy' else 503,
            'headers': {
                'Content-Type': 'application/json',
                'Cache-Control': 'no-cache'
            },
            'body': json.dumps(health_status, indent=2)
        }
        
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({
                'timestamp': datetime.utcnow().isoformat(),
                'overall_status': 'unhealthy',
                'error': str(e)
            })
        }

def check_rds_health():
    """
    Check RDS PostgreSQL database connectivity and basic functionality
    """
    try:
        # Get database connection parameters from environment
        host = os.environ.get('RDS_ENDPOINT')
        port = os.environ.get('RDS_PORT', '5432')
        database = os.environ.get('RDS_DATABASE')
        
        # Get credentials from Secrets Manager
        secrets_client = boto3.client('secretsmanager')
        secret_arn = os.environ.get('SECRET_ARN')
        
        if secret_arn:
            secret_response = secrets_client.get_secret_value(SecretId=secret_arn)
            secret_data = json.loads(secret_response['SecretString'])
            username = secret_data['username']
            password = secret_data['password']
        else:
            # Fallback to environment variables for development
            username = 'dbadmin'
            password = 'temp_password'
        
        # Test database connection
        start_time = datetime.utcnow()
        conn = psycopg2.connect(
            host=host,
            port=port,
            database=database,
            user=username,
            password=password,
            connect_timeout=10
        )
        
        # Execute a simple query
        cursor = conn.cursor()
        cursor.execute("SELECT version(), current_timestamp;")
        result = cursor.fetchone()
        
        cursor.close()
        conn.close()
        
        response_time = (datetime.utcnow() - start_time).total_seconds() * 1000
        
        return {
            'status': 'healthy',
            'response_time_ms': round(response_time, 2),
            'version': result[0].split(' ')[1] if result else 'unknown',
            'timestamp': result[1].isoformat() if result else None
        }
        
    except Exception as e:
        logger.error(f"RDS health check failed: {str(e)}")
        return {
            'status': 'unhealthy',
            'error': str(e)
        }

def check_redis_health():
    """
    Check Redis ElastiCache connectivity and basic functionality
    """
    try:
        # Get Redis connection parameters from environment
        host = os.environ.get('REDIS_ENDPOINT')
        port = int(os.environ.get('REDIS_PORT', '6379'))
        
        # Get auth token from Secrets Manager
        secrets_client = boto3.client('secretsmanager')
        secret_name = f"{os.environ.get('PROJECT_NAME', 'agent-platform')}-{os.environ.get('ENVIRONMENT', 'dev')}-redis-credentials"
        
        try:
            secret_response = secrets_client.get_secret_value(SecretId=secret_name)
            secret_data = json.loads(secret_response['SecretString'])
            auth_token = secret_data['auth_token']
        except:
            auth_token = None
        
        # Test Redis connection
        start_time = datetime.utcnow()
        
        if auth_token:
            r = redis.Redis(
                host=host,
                port=port,
                password=auth_token,
                ssl=True,
                socket_connect_timeout=10,
                socket_timeout=10
            )
        else:
            r = redis.Redis(
                host=host,
                port=port,
                socket_connect_timeout=10,
                socket_timeout=10
            )
        
        # Test basic operations
        r.ping()
        r.set('health_check', 'ok', ex=60)
        value = r.get('health_check')
        r.delete('health_check')
        
        response_time = (datetime.utcnow() - start_time).total_seconds() * 1000
        
        # Get Redis info
        info = r.info()
        
        return {
            'status': 'healthy',
            'response_time_ms': round(response_time, 2),
            'version': info.get('redis_version', 'unknown'),
            'memory_used': info.get('used_memory_human', 'unknown'),
            'connected_clients': info.get('connected_clients', 0)
        }
        
    except Exception as e:
        logger.error(f"Redis health check failed: {str(e)}")
        return {
            'status': 'unhealthy',
            'error': str(e)
        }

def check_eks_health():
    """
    Check EKS cluster status and basic functionality
    """
    try:
        # Get EKS cluster name from environment
        cluster_name = os.environ.get('EKS_CLUSTER')
        
        if not cluster_name:
            return {
                'status': 'unknown',
                'error': 'EKS cluster name not configured'
            }
        
        # Check cluster status using AWS API
        eks_client = boto3.client('eks')
        
        start_time = datetime.utcnow()
        cluster_response = eks_client.describe_cluster(name=cluster_name)
        response_time = (datetime.utcnow() - start_time).total_seconds() * 1000
        
        cluster = cluster_response['cluster']
        cluster_status = cluster['status']
        
        # Check node groups
        nodegroups_response = eks_client.list_nodegroups(clusterName=cluster_name)
        nodegroup_statuses = []
        
        for nodegroup_name in nodegroups_response['nodegroups']:
            ng_response = eks_client.describe_nodegroup(
                clusterName=cluster_name,
                nodegroupName=nodegroup_name
            )
            nodegroup_statuses.append({
                'name': nodegroup_name,
                'status': ng_response['nodegroup']['status'],
                'capacity': {
                    'desired': ng_response['nodegroup']['scalingConfig']['desiredSize'],
                    'min': ng_response['nodegroup']['scalingConfig']['minSize'],
                    'max': ng_response['nodegroup']['scalingConfig']['maxSize']
                }
            })
        
        # Determine overall EKS status
        if cluster_status == 'ACTIVE':
            unhealthy_nodegroups = [ng for ng in nodegroup_statuses if ng['status'] != 'ACTIVE']
            if unhealthy_nodegroups:
                status = 'degraded'
            else:
                status = 'healthy'
        else:
            status = 'unhealthy'
        
        return {
            'status': status,
            'response_time_ms': round(response_time, 2),
            'cluster_status': cluster_status,
            'cluster_version': cluster['version'],
            'endpoint': cluster['endpoint'],
            'nodegroups': nodegroup_statuses
        }
        
    except Exception as e:
        logger.error(f"EKS health check failed: {str(e)}")
        return {
            'status': 'unhealthy',
            'error': str(e)
        }

def check_aws_services():
    """
    Check AWS service availability and quotas
    """
    try:
        services_status = {}
        
        # Check Secrets Manager
        try:
            secrets_client = boto3.client('secretsmanager')
            secrets_client.list_secrets(MaxResults=1)
            services_status['secrets_manager'] = 'healthy'
        except Exception as e:
            services_status['secrets_manager'] = f'unhealthy: {str(e)}'
        
        # Check Systems Manager Parameter Store
        try:
            ssm_client = boto3.client('ssm')
            ssm_client.get_parameters_by_path(
                Path=f"/{os.environ.get('PROJECT_NAME', 'agent-platform')}/",
                MaxResults=1
            )
            services_status['parameter_store'] = 'healthy'
        except Exception as e:
            services_status['parameter_store'] = f'unhealthy: {str(e)}'
        
        # Check CloudWatch
        try:
            cloudwatch_client = boto3.client('cloudwatch')
            cloudwatch_client.list_metrics(MaxRecords=1)
            services_status['cloudwatch'] = 'healthy'
        except Exception as e:
            services_status['cloudwatch'] = f'unhealthy: {str(e)}'
        
        # Determine overall AWS services status
        unhealthy_services = [k for k, v in services_status.items() if not v.startswith('healthy')]
        
        if not unhealthy_services:
            overall_status = 'healthy'
        elif len(unhealthy_services) < len(services_status):
            overall_status = 'degraded'
        else:
            overall_status = 'unhealthy'
        
        return {
            'status': overall_status,
            'services': services_status
        }
        
    except Exception as e:
        logger.error(f"AWS services health check failed: {str(e)}")
        return {
            'status': 'unhealthy',
            'error': str(e)
        }


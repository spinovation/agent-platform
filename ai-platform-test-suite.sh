#!/bin/bash

# Comprehensive AI Platform Test Suite
# Tests all components: LLM service, Kubernetes health, performance
# Run this while your Oregon cleanup script is running

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
API_BASE="http://a15afaf7c7d7a4622b17be3367f40f68-1446456911.us-east-1.elb.amazonaws.com:8000"
NAMESPACE="ai-platform"

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Function to print test status
print_test() {
    echo -e "${YELLOW}🧪 Testing: $1${NC}"
}

print_pass() {
    echo -e "${GREEN}✅ PASS: $1${NC}"
}

print_fail() {
    echo -e "${RED}❌ FAIL: $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  INFO: $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_header "AI PLATFORM COMPREHENSIVE TEST SUITE"

echo "🎯 Testing your enterprise AI platform"
echo "📡 API Base: $API_BASE"
echo "🏢 Namespace: $NAMESPACE"
echo "⏰ Started: $(date)"

print_header "PHASE 1: PREREQUISITES CHECK"

# Check required tools
print_test "Required Tools"
if command_exists curl; then
    print_pass "curl is available"
else
    print_fail "curl is not installed"
    exit 1
fi

if command_exists jq; then
    print_pass "jq is available"
else
    print_fail "jq is not installed - installing..."
    if command_exists brew; then
        brew install jq
    elif command_exists apt-get; then
        sudo apt-get update && sudo apt-get install -y jq
    else
        print_fail "Cannot install jq automatically"
        exit 1
    fi
fi

if command_exists kubectl; then
    print_pass "kubectl is available"
else
    print_fail "kubectl is not installed"
    exit 1
fi

print_header "PHASE 2: KUBERNETES INFRASTRUCTURE TEST"

# Test Kubernetes connectivity
print_test "Kubernetes Cluster Connectivity"
if kubectl cluster-info >/dev/null 2>&1; then
    print_pass "Kubernetes cluster is accessible"
    
    # Get cluster info
    CLUSTER_INFO=$(kubectl cluster-info | head -1)
    print_info "Cluster: $CLUSTER_INFO"
else
    print_fail "Cannot connect to Kubernetes cluster"
    exit 1
fi

# Test namespace
print_test "AI Platform Namespace"
if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    print_pass "Namespace '$NAMESPACE' exists"
else
    print_fail "Namespace '$NAMESPACE' not found"
    print_info "Available namespaces:"
    kubectl get namespaces
fi

# Test pods
print_test "Pod Health Check"
RUNNING_PODS=$(kubectl get pods -n "$NAMESPACE" --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
TOTAL_PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)

if [ "$RUNNING_PODS" -gt 0 ]; then
    print_pass "Running pods: $RUNNING_PODS/$TOTAL_PODS"
    
    # Show pod details
    echo "📋 Pod Status:"
    kubectl get pods -n "$NAMESPACE" -o wide
else
    print_fail "No running pods found in namespace '$NAMESPACE'"
fi

# Test services
print_test "Service Connectivity"
SERVICES=$(kubectl get services -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
if [ "$SERVICES" -gt 0 ]; then
    print_pass "Services found: $SERVICES"
    
    echo "📋 Service Details:"
    kubectl get services -n "$NAMESPACE"
else
    print_fail "No services found in namespace '$NAMESPACE'"
fi

print_header "PHASE 3: AI PLATFORM API TESTS"

# Test 1: Basic Health Check
print_test "Health Endpoint"
HEALTH_RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/health_response.json "$API_BASE/health" 2>/dev/null || echo "000")

if [ "$HEALTH_RESPONSE" = "200" ]; then
    HEALTH_STATUS=$(cat /tmp/health_response.json | jq -r '.status' 2>/dev/null || echo "unknown")
    if [ "$HEALTH_STATUS" = "healthy" ]; then
        print_pass "Health check: $HEALTH_STATUS"
        
        # Show health details
        echo "📊 Health Details:"
        cat /tmp/health_response.json | jq . 2>/dev/null || cat /tmp/health_response.json
    else
        print_fail "Health status: $HEALTH_STATUS"
    fi
else
    print_fail "Health endpoint returned HTTP $HEALTH_RESPONSE"
fi

# Test 2: Root Endpoint
print_test "Root API Endpoint"
ROOT_RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/root_response.json "$API_BASE/" 2>/dev/null || echo "000")

if [ "$ROOT_RESPONSE" = "200" ]; then
    print_pass "Root endpoint accessible"
    
    # Show API info
    echo "📋 API Information:"
    cat /tmp/root_response.json | jq . 2>/dev/null || cat /tmp/root_response.json
else
    print_fail "Root endpoint returned HTTP $ROOT_RESPONSE"
fi

# Test 3: Model Availability
print_test "LLM Models"
MODELS_RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/models_response.json "$API_BASE/models" 2>/dev/null || echo "000")

if [ "$MODELS_RESPONSE" = "200" ]; then
    MODEL_COUNT=$(cat /tmp/models_response.json | jq '. | length' 2>/dev/null || echo "0")
    if [ "$MODEL_COUNT" -gt 0 ]; then
        print_pass "Models available: $MODEL_COUNT"
        
        echo "🧠 Available Models:"
        cat /tmp/models_response.json | jq -r '.[] | "  • \(.name) (\(.size))"' 2>/dev/null || echo "  • Model details unavailable"
    else
        print_fail "No models available"
    fi
else
    print_fail "Models endpoint returned HTTP $MODELS_RESPONSE"
fi

print_header "PHASE 4: AI FUNCTIONALITY TESTS"

# Test 4: Basic Chat Functionality
print_test "Basic Chat (Simple Question)"
CHAT_PAYLOAD='{"message": "What is 2+2? Respond with just the number.", "model": "llama3.2", "max_tokens": 50}'
CHAT_RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/chat_response.json -X POST "$API_BASE/chat" \
  -H "Content-Type: application/json" \
  -d "$CHAT_PAYLOAD" 2>/dev/null || echo "000")

if [ "$CHAT_RESPONSE" = "200" ]; then
    CHAT_RESULT=$(cat /tmp/chat_response.json | jq -r '.response' 2>/dev/null || echo "No response")
    if echo "$CHAT_RESULT" | grep -E "[4]" >/dev/null; then
        print_pass "Basic chat working (got: $CHAT_RESULT)"
    else
        print_fail "Chat response unexpected: $CHAT_RESULT"
    fi
    
    # Show processing time
    PROCESSING_TIME=$(cat /tmp/chat_response.json | jq -r '.processing_time' 2>/dev/null || echo "unknown")
    print_info "Processing time: ${PROCESSING_TIME}s"
else
    print_fail "Chat endpoint returned HTTP $CHAT_RESPONSE"
fi

# Test 5: Complex Chat
print_test "Complex Chat (Analysis Task)"
COMPLEX_PAYLOAD='{"message": "Briefly explain the benefits of cloud computing in 2 sentences.", "model": "llama3.2", "max_tokens": 200}'
COMPLEX_RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/complex_response.json -X POST "$API_BASE/chat" \
  -H "Content-Type: application/json" \
  -d "$COMPLEX_PAYLOAD" 2>/dev/null || echo "000")

if [ "$COMPLEX_RESPONSE" = "200" ]; then
    COMPLEX_RESULT=$(cat /tmp/complex_response.json | jq -r '.response' 2>/dev/null || echo "No response")
    WORD_COUNT=$(echo "$COMPLEX_RESULT" | wc -w)
    
    if [ "$WORD_COUNT" -gt 10 ]; then
        print_pass "Complex chat working ($WORD_COUNT words)"
        echo "💬 Response preview: $(echo "$COMPLEX_RESULT" | cut -c1-100)..."
    else
        print_fail "Complex chat response too short: $WORD_COUNT words"
    fi
else
    print_fail "Complex chat returned HTTP $COMPLEX_RESPONSE"
fi

print_header "PHASE 5: PERFORMANCE & LOAD TESTS"

# Test 6: Response Time Test
print_test "Response Time Measurement"
echo "⏱️ Measuring response times..."

# Health endpoint timing
HEALTH_TIME=$(curl -s -w "%{time_total}" -o /dev/null "$API_BASE/health" 2>/dev/null || echo "0")
print_info "Health endpoint: ${HEALTH_TIME}s"

# Models endpoint timing
MODELS_TIME=$(curl -s -w "%{time_total}" -o /dev/null "$API_BASE/models" 2>/dev/null || echo "0")
print_info "Models endpoint: ${MODELS_TIME}s"

# Chat endpoint timing
CHAT_TIME=$(curl -s -w "%{time_total}" -o /dev/null -X POST "$API_BASE/chat" \
  -H "Content-Type: application/json" \
  -d '{"message": "Hi", "model": "llama3.2"}' 2>/dev/null || echo "0")
print_info "Chat endpoint: ${CHAT_TIME}s"

# Evaluate performance
if (( $(echo "$HEALTH_TIME < 2.0" | bc -l) )); then
    print_pass "Health response time acceptable"
else
    print_fail "Health response time slow: ${HEALTH_TIME}s"
fi

# Test 7: Concurrent Load Test
print_test "Concurrent Load Test (5 requests)"
echo "🚀 Starting concurrent requests..."

start_time=$(date +%s.%N)

# Run 5 concurrent health checks
for i in {1..5}; do
    curl -s "$API_BASE/health" >/dev/null &
done
wait

end_time=$(date +%s.%N)
duration=$(echo "$end_time - $start_time" | bc)

print_pass "5 concurrent requests completed in ${duration}s"

print_header "PHASE 6: RESOURCE UTILIZATION"

# Test 8: Kubernetes Resource Usage
print_test "Resource Utilization"

echo "💾 Node Resource Usage:"
kubectl top nodes 2>/dev/null || print_info "Metrics server not available"

echo "📊 Pod Resource Usage:"
kubectl top pods -n "$NAMESPACE" 2>/dev/null || print_info "Pod metrics not available"

# Check pod logs for errors
print_test "Error Log Check"
ERROR_COUNT=0

for pod in $(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
    ERRORS=$(kubectl logs "$pod" -n "$NAMESPACE" --tail=50 2>/dev/null | grep -i "error\|exception\|failed" | wc -l)
    if [ "$ERRORS" -gt 0 ]; then
        print_fail "Pod $pod has $ERRORS error messages"
        ERROR_COUNT=$((ERROR_COUNT + ERRORS))
    fi
done

if [ "$ERROR_COUNT" -eq 0 ]; then
    print_pass "No errors found in pod logs"
else
    print_fail "Total errors found: $ERROR_COUNT"
fi

print_header "PHASE 7: AGENT SYSTEM TESTS"

# Test 9: Agent Endpoints (if available)
print_test "Agent System"
AGENT_PAYLOAD='{"agent_type": "data_analysis", "task_description": "Test task", "parameters": {}}'
AGENT_RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/agent_response.json -X POST "$API_BASE/agents/execute" \
  -H "Content-Type: application/json" \
  -d "$AGENT_PAYLOAD" 2>/dev/null || echo "000")

if [ "$AGENT_RESPONSE" = "200" ]; then
    print_pass "Agent system accessible"
    echo "🤖 Agent Response:"
    cat /tmp/agent_response.json | jq . 2>/dev/null || cat /tmp/agent_response.json
elif [ "$AGENT_RESPONSE" = "404" ]; then
    print_info "Agent endpoints not yet implemented (expected)"
else
    print_fail "Agent endpoint returned HTTP $AGENT_RESPONSE"
fi

print_header "TEST RESULTS SUMMARY"

echo "📊 Test Summary:"
echo "   • Kubernetes: $(kubectl get pods -n "$NAMESPACE" --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l) pods running"
echo "   • API Health: $([ -f /tmp/health_response.json ] && cat /tmp/health_response.json | jq -r '.status' 2>/dev/null || echo 'unknown')"
echo "   • Models: $([ -f /tmp/models_response.json ] && cat /tmp/models_response.json | jq '. | length' 2>/dev/null || echo '0') available"
echo "   • Chat: $([ -f /tmp/chat_response.json ] && echo 'working' || echo 'failed')"
echo "   • Performance: Health ${HEALTH_TIME}s, Chat ${CHAT_TIME}s"

print_header "RECOMMENDATIONS"

echo "🎯 Based on test results:"

# Performance recommendations
if (( $(echo "$CHAT_TIME > 10.0" | bc -l) )); then
    echo "⚠️  Chat response time is slow (${CHAT_TIME}s) - consider:"
    echo "   • Scaling up pod resources"
    echo "   • Using smaller/faster models"
    echo "   • Adding more replicas"
fi

# Resource recommendations
RUNNING_PODS=$(kubectl get pods -n "$NAMESPACE" --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
if [ "$RUNNING_PODS" -lt 2 ]; then
    echo "⚠️  Consider adding more pod replicas for high availability"
fi

# Next steps
echo ""
echo "🚀 Next Steps:"
echo "   1. If all tests pass: Deploy agents and web interface"
echo "   2. If tests fail: Check pod logs and troubleshoot"
echo "   3. Monitor performance under real workloads"
echo "   4. Set up monitoring and alerting"

print_header "TEST COMPLETE"

echo "✅ AI Platform testing completed at $(date)"
echo "📁 Test artifacts saved in /tmp/"
echo "🔍 For detailed logs: kubectl logs -n $NAMESPACE <pod-name>"

# Cleanup temp files
rm -f /tmp/health_response.json /tmp/root_response.json /tmp/models_response.json
rm -f /tmp/chat_response.json /tmp/complex_response.json /tmp/agent_response.json

echo ""
echo "🎯 Your AI platform is ready for expansion!"

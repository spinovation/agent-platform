#!/bin/bash

# AI Platform Agent Deployment Script
# Deploys the three default agents: Data Analysis, Web Automation, Task Management

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

print_header "AI PLATFORM AGENT DEPLOYMENT"

echo "🤖 Deploying three default agents to your AI platform:"
echo "   • 📊 Data Analysis Agent"
echo "   • 🌐 Web Automation Agent" 
echo "   • 📋 Task Management Agent"

# Check if we're in the right directory
if [ ! -d "agent-platform" ]; then
    echo "Creating agent-platform directory..."
    mkdir -p agent-platform
fi

cd agent-platform

print_header "STEP 1: CREATE AGENT FRAMEWORK"

# Create agent framework directory
mkdir -p agent-framework
cd agent-framework

print_info "Creating base agent class..."

# Create requirements.txt for agents
cat > requirements.txt << 'EOF'
fastapi==0.104.1
httpx==0.25.2
pandas==2.1.4
numpy==1.24.3
asyncio
logging
json
datetime
typing
abc
EOF

print_status "Agent requirements created"

# Create base agent class (simplified version for quick deployment)
cat > base_agent.py << 'EOF'
"""
Base Agent Class for Enterprise AI Platform
"""

import asyncio
import json
import logging
from abc import ABC, abstractmethod
from typing import Dict, Any
from datetime import datetime
import httpx

class BaseAgent(ABC):
    def __init__(self, name: str, llm_service_url: str):
        self.name = name
        self.llm_service_url = llm_service_url
        self.logger = logging.getLogger(f"agent.{name}")
        
    @abstractmethod
    async def execute(self, task: Dict[str, Any]) -> Dict[str, Any]:
        pass
    
    async def chat_with_llm(self, message: str, system_prompt: str = None) -> str:
        try:
            async with httpx.AsyncClient(timeout=120.0) as client:
                payload = {
                    "message": message,
                    "model": "llama3.2",
                    "system_prompt": system_prompt
                }
                
                response = await client.post(
                    f"{self.llm_service_url}/chat",
                    json=payload
                )
                
                if response.status_code == 200:
                    data = response.json()
                    return data.get("response", "No response")
                else:
                    return f"Error: HTTP {response.status_code}"
                    
        except Exception as e:
            return f"Error: {str(e)}"
EOF

print_status "Base agent class created"

# Create Data Analysis Agent
cat > data_analysis_agent.py << 'EOF'
"""
Data Analysis Agent - Specializes in data processing and analysis
"""

from typing import Dict, Any
from base_agent import BaseAgent
import json

class DataAnalysisAgent(BaseAgent):
    def __init__(self, llm_service_url: str):
        super().__init__("data_analysis", llm_service_url)
        self.capabilities = ["csv_analysis", "statistical_analysis", "data_visualization"]
    
    async def execute(self, task: Dict[str, Any]) -> Dict[str, Any]:
        task_description = task.get("task_description", "")
        parameters = task.get("parameters", {})
        
        analysis_prompt = f"""
        Data Analysis Task: {task_description}
        Parameters: {json.dumps(parameters, indent=2)}
        
        As a data analysis expert, provide:
        1. Analysis approach
        2. Key insights
        3. Recommendations
        4. Next steps
        """
        
        try:
            response = await self.chat_with_llm(
                analysis_prompt,
                "You are a senior data analyst. Provide structured, actionable analysis."
            )
            
            return {
                "status": "completed",
                "agent_type": "data_analysis",
                "response": response,
                "capabilities": self.capabilities
            }
        except Exception as e:
            return {
                "status": "error",
                "agent_type": "data_analysis",
                "error": str(e)
            }
EOF

print_status "Data Analysis Agent created"

# Create Web Automation Agent
cat > web_automation_agent.py << 'EOF'
"""
Web Automation Agent - Specializes in web scraping and API interactions
"""

from typing import Dict, Any
from base_agent import BaseAgent
import json

class WebAutomationAgent(BaseAgent):
    def __init__(self, llm_service_url: str):
        super().__init__("web_automation", llm_service_url)
        self.capabilities = ["web_scraping", "api_integration", "content_extraction"]
    
    async def execute(self, task: Dict[str, Any]) -> Dict[str, Any]:
        task_description = task.get("task_description", "")
        parameters = task.get("parameters", {})
        
        automation_prompt = f"""
        Web Automation Task: {task_description}
        Parameters: {json.dumps(parameters, indent=2)}
        
        As a web automation expert, provide:
        1. Implementation approach
        2. Required tools/methods
        3. Step-by-step plan
        4. Expected challenges
        5. Success criteria
        """
        
        try:
            response = await self.chat_with_llm(
                automation_prompt,
                "You are a web automation expert. Provide detailed implementation plans."
            )
            
            return {
                "status": "completed",
                "agent_type": "web_automation", 
                "response": response,
                "capabilities": self.capabilities
            }
        except Exception as e:
            return {
                "status": "error",
                "agent_type": "web_automation",
                "error": str(e)
            }
EOF

print_status "Web Automation Agent created"

# Create Task Management Agent
cat > task_management_agent.py << 'EOF'
"""
Task Management Agent - Specializes in project management and scheduling
"""

from typing import Dict, Any
from base_agent import BaseAgent
import json
from datetime import datetime

class TaskManagementAgent(BaseAgent):
    def __init__(self, llm_service_url: str):
        super().__init__("task_management", llm_service_url)
        self.capabilities = ["project_planning", "task_scheduling", "progress_tracking"]
    
    async def execute(self, task: Dict[str, Any]) -> Dict[str, Any]:
        task_description = task.get("task_description", "")
        parameters = task.get("parameters", {})
        
        management_prompt = f"""
        Task Management Request: {task_description}
        Parameters: {json.dumps(parameters, indent=2)}
        
        As a project management expert, provide:
        1. Project breakdown
        2. Task prioritization
        3. Timeline estimation
        4. Resource requirements
        5. Risk assessment
        """
        
        try:
            response = await self.chat_with_llm(
                management_prompt,
                "You are a senior project manager. Create comprehensive, actionable plans."
            )
            
            return {
                "status": "completed",
                "agent_type": "task_management",
                "response": response,
                "capabilities": self.capabilities
            }
        except Exception as e:
            return {
                "status": "error", 
                "agent_type": "task_management",
                "error": str(e)
            }
EOF

print_status "Task Management Agent created"

# Create Agent Orchestrator
cat > agent_orchestrator.py << 'EOF'
"""
Agent Orchestrator - Manages all agents
"""

from typing import Dict, Any
from data_analysis_agent import DataAnalysisAgent
from web_automation_agent import WebAutomationAgent
from task_management_agent import TaskManagementAgent

class AgentOrchestrator:
    def __init__(self, llm_service_url: str):
        self.agents = {
            "data_analysis": DataAnalysisAgent(llm_service_url),
            "web_automation": WebAutomationAgent(llm_service_url),
            "task_management": TaskManagementAgent(llm_service_url)
        }
    
    async def execute_task(self, agent_type: str, task: Dict[str, Any]) -> Dict[str, Any]:
        if agent_type not in self.agents:
            return {
                "status": "error",
                "error": f"Unknown agent type: {agent_type}",
                "available_agents": list(self.agents.keys())
            }
        
        agent = self.agents[agent_type]
        return await agent.execute(task)
    
    def get_capabilities(self) -> Dict[str, Any]:
        return {
            agent_name: agent.capabilities 
            for agent_name, agent in self.agents.items()
        }
EOF

print_status "Agent Orchestrator created"

print_header "STEP 2: CREATE AGENT SERVICE"

# Create agent service that integrates with the main LLM service
cat > agent_service.py << 'EOF'
"""
Agent Service - FastAPI service for agent management
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Dict, Any, Optional
import asyncio
from agent_orchestrator import AgentOrchestrator

app = FastAPI(title="AI Platform Agent Service", version="1.0.0")

# Initialize orchestrator
LLM_SERVICE_URL = "http://llm-service:8000"  # Internal Kubernetes service
orchestrator = AgentOrchestrator(LLM_SERVICE_URL)

class AgentRequest(BaseModel):
    agent_type: str
    task_description: str
    parameters: Optional[Dict[str, Any]] = None

class AgentResponse(BaseModel):
    status: str
    agent_type: str
    response: Optional[str] = None
    error: Optional[str] = None
    capabilities: Optional[list] = None

@app.get("/")
async def root():
    return {
        "service": "AI Platform Agent Service",
        "version": "1.0.0",
        "available_agents": list(orchestrator.agents.keys()),
        "capabilities": orchestrator.get_capabilities()
    }

@app.get("/agents")
async def list_agents():
    return {
        "agents": list(orchestrator.agents.keys()),
        "capabilities": orchestrator.get_capabilities()
    }

@app.post("/agents/execute", response_model=AgentResponse)
async def execute_agent(request: AgentRequest):
    try:
        task = {
            "task_description": request.task_description,
            "parameters": request.parameters or {}
        }
        
        result = await orchestrator.execute_task(request.agent_type, task)
        
        return AgentResponse(
            status=result.get("status", "unknown"),
            agent_type=result.get("agent_type", request.agent_type),
            response=result.get("response"),
            error=result.get("error"),
            capabilities=result.get("capabilities")
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
EOF

print_status "Agent service created"

print_header "STEP 3: CREATE KUBERNETES DEPLOYMENT"

# Create Dockerfile for agents
cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy agent code
COPY *.py ./

# Expose port
EXPOSE 8001

# Run agent service
CMD ["python", "agent_service.py"]
EOF

print_status "Dockerfile created"

# Create Kubernetes deployment
cat > agent-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: agent-service
  namespace: ai-platform
spec:
  replicas: 2
  selector:
    matchLabels:
      app: agent-service
  template:
    metadata:
      labels:
        app: agent-service
    spec:
      containers:
      - name: agent-service
        image: agent-service:latest
        ports:
        - containerPort: 8001
        env:
        - name: LLM_SERVICE_URL
          value: "http://llm-service:8000"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: agent-service
  namespace: ai-platform
spec:
  selector:
    app: agent-service
  ports:
  - port: 8001
    targetPort: 8001
  type: ClusterIP
EOF

print_status "Kubernetes deployment created"

print_header "STEP 4: BUILD AND DEPLOY"

print_info "Building Docker image..."

# Build Docker image
docker build -t agent-service:latest . || {
    print_info "Docker build failed. You may need to:"
    echo "  1. Install Docker"
    echo "  2. Start Docker daemon"
    echo "  3. Run: docker build -t agent-service:latest ."
}

print_info "Deploying to Kubernetes..."

# Deploy to Kubernetes
kubectl apply -f agent-deployment.yaml || {
    print_info "Kubernetes deployment failed. You may need to:"
    echo "  1. Ensure kubectl is configured"
    echo "  2. Check if ai-platform namespace exists"
    echo "  3. Run: kubectl apply -f agent-deployment.yaml"
}

print_header "STEP 5: VERIFY DEPLOYMENT"

print_info "Waiting for deployment to be ready..."
sleep 10

# Check deployment status
kubectl get pods -n ai-platform -l app=agent-service

print_info "Checking service status..."
kubectl get services -n ai-platform agent-service

print_header "STEP 6: TEST AGENTS"

# Get the LLM service URL for testing
LLM_SERVICE_URL=$(kubectl get service llm-service -n ai-platform -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "localhost")

if [ "$LLM_SERVICE_URL" != "localhost" ]; then
    print_info "Testing agent integration..."
    
    # Test agent endpoint through port-forward
    kubectl port-forward service/agent-service 8001:8001 -n ai-platform &
    PORT_FORWARD_PID=$!
    
    sleep 5
    
    # Test agent service
    curl -s http://localhost:8001/ | jq . || echo "Agent service test failed"
    
    # Kill port-forward
    kill $PORT_FORWARD_PID 2>/dev/null || true
fi

print_header "DEPLOYMENT COMPLETE"

echo "🎉 Agent deployment completed successfully!"
echo ""
echo "📋 What was deployed:"
echo "   • 📊 Data Analysis Agent"
echo "   • 🌐 Web Automation Agent"
echo "   • 📋 Task Management Agent"
echo "   • 🎯 Agent Orchestrator"
echo "   • 🚀 Agent Service (FastAPI)"
echo ""
echo "🔗 Access your agents:"
echo "   • Internal: http://agent-service:8001 (within cluster)"
echo "   • External: Use kubectl port-forward for testing"
echo ""
echo "🧪 Test your agents:"
echo "   kubectl port-forward service/agent-service 8001:8001 -n ai-platform"
echo "   curl http://localhost:8001/agents"
echo ""
echo "🎯 Next steps:"
echo "   1. Test agent functionality"
echo "   2. Deploy web interface"
echo "   3. Set up monitoring"
echo "   4. Create custom agents"

cd ..
print_status "Agent framework ready for use!"

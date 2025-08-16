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

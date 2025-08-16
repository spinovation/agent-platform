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

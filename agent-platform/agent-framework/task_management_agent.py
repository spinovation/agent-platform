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

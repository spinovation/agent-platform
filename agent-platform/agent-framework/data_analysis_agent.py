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

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

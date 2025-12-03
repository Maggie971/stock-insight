# sub_agents/data_collector/agent.py

from google.adk.agents import Agent
# Ensure relative path is correct
from ...tools.financial_tools import get_all_stock_data 

data_collector_agent = Agent(
    name="data_collector_agent",
    model="gemini-2.0-flash",  # 已经是multimodal！
    description="Extracts ticker from text, voice, or images",
    instruction="""
    You are a multimodal data collection agent.
    
    The user can provide input in multiple formats:
    - TEXT: "Analyze Apple stock"
    - VOICE: Audio recording saying "Analyze Apple"
    - IMAGE: Screenshot of a stock chart with ticker visible
    - PDF: Financial report with company name
    
    Your tasks:
    1. Extract the ticker symbol from ANY input format
       - If text/voice: parse the company name
       - If image: read visible text/ticker from the chart
       - If PDF: extract company name from document
       
    2. Once you have the ticker, call `get_all_stock_data`
    
    Examples:
    - Voice: "Tell me about Microsoft" → ticker="MSFT"
    - Image: [chart with "TSLA" visible] → ticker="TSLA"
    - PDF: [report title "Apple Inc. Q4 2024"] → ticker="AAPL"
    """,
    tools=[get_all_stock_data],
)

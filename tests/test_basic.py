def test_imports():
    from app.sub_agents.fundamental.agent import fundamental_analysis_agent
    assert fundamental_analysis_agent is not None
    
def test_tools():
    from app.tools.financial_tools import get_stock_price
    assert get_stock_price is not None
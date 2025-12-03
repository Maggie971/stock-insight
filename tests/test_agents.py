"""
Simple tests for Stock Insight agents
"""

def test_import_agents():
    """Test that all agents can be imported"""
    try:
        from app.sub_agents.data_collector.agent import data_collector_agent
        from app.sub_agents.fundamental.agent import fundamental_analysis_agent
        from app.sub_agents.valuation.agent import valuation_analysis_agent
        from app.sub_agents.risks.agent import risk_analysis_agent
        from app.sub_agents.aggregator.agent import aggregator_agent
        from app.sub_agents.planner.agent import stock_analysis_planner
        from app.agent import root_agent
        
        assert data_collector_agent is not None
        assert fundamental_analysis_agent is not None
        assert valuation_analysis_agent is not None
        assert risk_analysis_agent is not None
        assert aggregator_agent is not None
        assert stock_analysis_planner is not None
        assert root_agent is not None
        
        print("✅ All agents imported successfully")
        
    except ImportError as e:
        raise AssertionError(f"Failed to import agents: {e}")


def test_agent_configuration():
    """Test that agents have proper configuration"""
    from app.sub_agents.fundamental.agent import fundamental_analysis_agent
    
    # Check that fundamental agent uses fine-tuned model
    assert fundamental_analysis_agent.model is not None
    assert "endpoints" in str(fundamental_analysis_agent.model) or \
           "luminous-return-441222-f4" in str(fundamental_analysis_agent.model)
    
    print(f"✅ Fundamental agent model: {fundamental_analysis_agent.model}")


def test_tools_import():
    """Test that tools can be imported"""
    try:
        from app.tools.financial_tools import get_stock_price, get_all_stock_data
        
        assert get_stock_price is not None
        assert get_all_stock_data is not None
        
        print("✅ Tools imported successfully")
        
    except ImportError as e:
        raise AssertionError(f"Failed to import tools: {e}")


if __name__ == "__main__":
    test_import_agents()
    test_agent_configuration()
    test_tools_import()
    print("\n🎉 All tests passed!")
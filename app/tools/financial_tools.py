# tools/financial_tools.py

import yfinance as yf
from typing import Dict, Any

def _safe_get(info: Dict[str, Any], key: str, default: Any = None) -> Any:
    """Helper for safely extracting values, handling None, 'N/A', and empty dicts/lists."""
    val = info.get(key, default)
    # yfinance often returns strings like 'None' or empty containers, standardize them to Python None
    if val in (None, 'N/A', {}, []):
        return None
    return val

def get_all_stock_data(ticker: str) -> Dict[str, Any]:
    """
    Fetches price, financial metrics, and news in a single, consistent call.
    This eliminates data freshness issues caused by multiple yfinance calls.
    """
    try:
        stock = yf.Ticker(ticker)
        info = stock.info
        news_data = stock.news
        
        # 1. Price Data (using multiple fallbacks for robustness)
        price = (_safe_get(info, 'currentPrice') or 
                 _safe_get(info, 'regularMarketPrice') or 
                 _safe_get(info, 'previousClose'))
        
        if price is None:
            return {"status": "error", "error_message": f"Could not find price or fundamental data for {ticker}"}

        # 2. Metrics Data
        metrics = {
            "revenue": _safe_get(info, 'totalRevenue'),
            "revenue_growth": _safe_get(info, 'revenueGrowth'),
            "profit_margin": _safe_get(info, 'profitMargins'),
            "cash_flow": _safe_get(info, 'operatingCashflow'),
            "pe_ratio": _safe_get(info, 'trailingPE'),
            "ps_ratio": _safe_get(info, 'priceToSales'),
            "pb_ratio": _safe_get(info, 'priceToBook'),
            "market_cap": _safe_get(info, 'marketCap')
        }
        
        # 3. News Data
        # Limit to 5 headlines and filter out any None titles
        headlines = [_safe_get(item, 'title') for item in news_data if _safe_get(item, 'title') is not None][:5]
        
        return {
            "status": "success",
            "ticker": ticker,
            "current_price": float(price),
            "currency": _safe_get(info, 'currency', 'USD'),
            "metrics": metrics,
            "headlines": headlines
        }

    except Exception as e:
        return {"status": "error", "error_message": f"Error fetching all data for {ticker}: {str(e)}"}

def get_stock_price(ticker: str) -> Dict[str, Any]:
    """Gets the current stock price for a ticker (Used by root_agent for fast path)."""
    data = get_all_stock_data(ticker)
    if data['status'] == 'success':
        return {
            "status": "success",
            "ticker": data['ticker'],
            "price": data['current_price'],
            "currency": data['currency']
        }
    return data # Returns the error dictionary if fetching failed

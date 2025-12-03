# Stock-Insight — Multi-Agent LLM Stock Analysis System

Stock-Insight is a multi-agent financial analysis system powered by **Google ADK**.
It behaves like a small research team: one agent collects data, others analyze fundamentals,
risks, and valuation, and a final writer produces a clean, structured stock report.

## Features

- **Price Lookup** – Real-time stock prices via Yahoo Finance  
- **Automated Data Collection** – Financial metrics + valuation ratios + latest news  
- **Fundamental Analysis** – Revenue, margins, cash flow overview  
- **Risk Analysis** – Extract risks from recent headlines  
- **Valuation Analysis** – Interpret PE, PS, Forward PE  
- **Final Report Writer** – Generates a polished Markdown analysis  
- **Planner Agent** – Orchestrates a 5-step workflow:
  ```
  data → fundamental → risk → valuation → final_writer
  ```

## Architecture

```
stock_insight/
│
├── root_agent.py
├── tools/
│   └── financial_tools.py
│
└── sub_agents/
    ├── planner/
    │   └── agent.py
    │
    ├── data_collector/
    │   └── agent.py
    │
    ├── fundamental/
    │   └── agent.py
    │
    ├── valuation/
    │   └── agent.py
    │
    ├── risks/
    │   └── agent.py
    │
    └── aggregator/
        └── agent.py
```

```
Root Agent
   ↓
Planner Agent
   ↓
Data Collector Agent
   ↓
---------------------------------------
↓ Fundamental Analysis Agent
↓ Valuation Analysis Agent
↓ Risk Analysis Agent
---------------------------------------
   ↓
Aggregator Agent
   ↓
Final Markdown Report
```

## Setup

```bash
git clone https://github.com/zhangxijing97/stock-insight.git
cd stock-insight
pip install -r requirements.txt
```

Create a `.env` file:

```bash
GOOGLE_GENAI_USE_VERTEXAI=0
GOOGLE_API_KEY=your_api_key_here
```

## ▶️ Run

### Developer UI
```bash
adk web
```

### Production API Server
```bash
adk serve
```

## Example Usage

**Price only**
```
What is the price of AAPL?
```

**Full analysis**
```
Give me a full analysis of TSLA.
```

**Ambiguous**
```
Tell me about MSFT.
```
Root agent will ask whether you want **price** or **full report**.

## Sample Output

```
## Stock Analysis Report: AAPL
**Current Price:** $183.12

### Fundamental Analysis
...

### Valuation Analysis
...
---

## LLMOps Project Requirements — Detailed Checklist

### 1. Fine-tuning or domain adaptation of an existing LLM.
- [✔️] Fine-tuning  
  - Built a fundamental analysis dataset and converted it to Vertex AI JSONL format.  
  - Fine-tuned Gemini on this dataset to improve financial analysis quality.  
- [ ] Domain adaptation  

### 2. Multi-agent orchestration—agents collaborating or competing to perform tasks (e.g., planner–executor, retriever–summarizer, or debate-style reasoning).
- [✔️] Multi-agent orchestration—agents  
  - Implemented a multi-agent pipeline with specialized agents for data collection, analysis, and report generation.  
- [✔️] Planner–Executor Pattern  
  - Used a planner agent to coordinate the sequence of expert agents and produce a consolidated final output.  

### 3. API-based response systems—handling multi-source or multi-modal queries.
- [✔️] Multi-source query handling  
  - Integrates real-time financial data from the yfinance API with internal multi-agent analysis outputs (fundamental, valuation, and risk).  
  - The planner combines these heterogeneous data sources into a unified response pipeline.
- [ ] Multi-modal queries  

### 4. PromptOps: prompt design, management, and evaluation pipelines.
- [✔️] Prompt design & management  
  - Each agent has a structured, task-specific system prompt (planner, data collector, analysts, aggregator), forming a maintainable multi-agent prompt hierarchy.
- [✔️] Prompt evaluation  
  - Prompts were iteratively refined based on output quality, enforcing strict formatting rules and reliable tool-call behavior across agents.

### 5. Monitoring and governance—evaluation, logging, and safety controls.

### 6. Include a simplified CI/CD pipeline that demonstrates automated testing, versioning, and deployment of LLM components or services.


### Output before Fine-tuning
```
Here is a stock analysis report for AAPL:

Current Price: $267.44

Fundamental Analysis: Apple is a mega-cap company with a market capitalization of nearly $4 trillion. It generates substantial revenue, exceeding $416 billion, and has demonstrated a healthy revenue growth of 7.9%. The company exhibits strong profitability with a profit margin of 26.9%. Apple's robust cash flow, which is over $111 billion, further indicates financial strength.

Valuation Analysis: AAPL's valuation indicates a potentially expensive stock. The PE ratio of 35.85 suggests investors are paying a premium for each dollar of earnings, possibly reflecting high growth expectations. Similarly, a high PB ratio of 53.58 could signal overvaluation relative to its book value. However, the strong profit margin of 26.92% and recent revenue growth of 7.9% provide some justification for the higher multiples.

Key Risks:

High valuation ratios (P/E, P/S) suggest potential overvaluation.
Dependence on a few key products makes revenue susceptible to innovation slowdown or competition.
Profit margins, while strong, could be vulnerable to rising component costs or pricing pressure.
Cash flow, though positive, needs to be monitored for efficient capital allocation and shareholder returns.
```

### Output after Fine-tuning
```
Here is the Stock Analysis Report for Apple (AAPL):

Current Price: $268.56

Fundamental Analysis: Apple maintains robust fundamentals supported by diversified hardware and high-growth services. Its ~$4T market cap reflects strong brand equity and ecosystem loyalty. Margins in the mid-20% range highlight disciplined cost control and strong mix benefits. Net cash-flow generation exceeding $111B supports ongoing capital returns and strategic investment. Analysts see long-term visibility tied to continued customer engagement. Overall, Apple remains a high-quality global growth story.

Valuation Analysis: Apple's valuation presents a mixed picture. Its PE ratio of 35.95 suggests that the market has priced in future earnings growth, or that the stock is potentially overvalued compared to its current earnings. The PB ratio of 53.81 also points to a high valuation relative to its book value. The strong profit margin of 26.9% and recent revenue growth of 7.9% support a premium valuation, but investors should consider whether the current price adequately reflects future growth prospects.

Key Risks:

High valuation (PE Ratio) suggests potential for price correction if growth slows.
Dependence on a few key products (e.g., iPhone) makes revenue susceptible to market shifts.
Intense competition in the smartphone and consumer electronics markets could erode market share.
Profit margins could be squeezed by rising component costs or pricing pressure.
```# Test CI/CD

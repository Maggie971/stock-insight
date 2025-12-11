# TradeSeer AI - Multi-Agent Stock Analysis System

TradeSeer AI is a production-ready financial analysis chatbot powered by **Google ADK** and **fine-tuned Gemini models**. It operates as an intelligent research team: specialized agents collaborate to collect data, analyze fundamentals, assess valuation and risks, and generate professional stock reports.

## Features

- **Multimodal Input** - Text queries, stock chart images, PDF financial documents
- **Price Lookup** - Real-time stock prices via Yahoo Finance
- **Automated Data Collection** - Financial metrics, valuation ratios, latest news headlines
- **Fundamental Analysis** - Revenue, margins, cash flow analysis (powered by fine-tuned model)
- **Risk Analysis** - Extracts risks from headlines and financial metrics
- **Valuation Analysis** - Interprets PE, PS, PB ratios with qualitative reasoning
- **Chart Reading** - Analyzes uploaded stock charts for trends, support/resistance levels
- **PDF Processing** - Extracts structured data from financial reports with dual-mode output
- **Multi-Agent Orchestration** - Planner coordinates 6 specialized agents:
  ```
  data_collector → [fundamental + valuation + risk] → aggregator → report
  ```
- **Production Deployment** - Containerized with Docker, deployed on Google Kubernetes Engine
- **CI/CD Pipeline** - Automated testing, building, and deployment via GitHub Actions

## Architecture

### Project Structure

```
tradeseer-ai/
│
├── app/
│   ├── agent.py (root_agent)
│   ├── tools/
│   │   └── financial_tools.py
│   │
│   └── sub_agents/
│       ├── planner/
│       │   └── agent.py
│       ├── data_collector/
│       │   └── agent.py
│       ├── fundamental/
│       │   └── agent.py (fine-tuned model)
│       ├── valuation/
│       │   └── agent.py
│       ├── risks/
│       │   └── agent.py
│       ├── chart_analyzer/
│       │   └── agent.py
│       └── aggregator/
│           └── agent.py
│
├── k8s-gke/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── secret.yaml (template)
│
├── cicd/
│   ├── deploy.sh
│   └── quick-deploy.sh
│
├── .github/
│   └── workflows/
│       └── deploy.yaml
│
├── tests/
│   └── test_agents.py
│
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
└── .env.example
```

### Agent Flow

```
User Input (Text/Image/PDF)
   ↓
Root Agent (Routes query)
   ↓
   ├─ get_stock_price (simple price query)
   │
   ├─ Direct processing (chart/PDF reading)
   │
   └─ stock_analysis_planner (full analysis)
       ↓
       Data Collector Agent
       ↓
       ┌────────────────┬────────────────┬────────────────┐
       ↓                ↓                ↓                ↓
   Fundamental      Valuation        Risk            Chart
   (Fine-tuned)     (Gemini)        (Gemini)       (Gemini)
       └────────────────┴────────────────┴────────────────┘
                            ↓
                    Aggregator Agent
                            ↓
                   Markdown Report
```

## Setup

### Prerequisites

- Python 3.11+
- Docker and Docker Buildx
- Google Cloud SDK (`gcloud`)
- kubectl
- GCP project with Vertex AI API enabled

### Local Development

1. Clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/tradeseer-ai.git
cd tradeseer-ai
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Configure environment variables:
```bash
cp .env.example .env
# Edit .env and fill in your credentials
```

Example `.env`:
```bash
GOOGLE_GENAI_USE_VERTEXAI=1
GOOGLE_API_KEY=your_api_key_here
GOOGLE_CLOUD_PROJECT=your_project_id
GOOGLE_CLOUD_LOCATION=us-west1
```

4. Run locally:
```bash
# Web UI
adk web --host 0.0.0.0 --port 8000

# Or production server
adk serve
```

Access at `http://localhost:8000`

---

## Docker Deployment

### Build and Run with Docker

```bash
# Build image
docker build -t tradeseer-ai .

# Run container
docker run -d \
  --env-file .env \
  -p 8000:5173 \
  --name tradeseer \
  tradeseer-ai
```

### Using Docker Compose

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

---

## Kubernetes Deployment

### Prerequisites

- GKE cluster running
- `kubectl` configured for your cluster
- Service account with Vertex AI permissions

### Manual Deployment

1. Create service account key:
```bash
gcloud iam service-accounts keys create sa-key.json \
  --iam-account=stock-insight-key@YOUR_PROJECT.iam.gserviceaccount.com
```

2. Create Kubernetes secrets:
```bash
# Create GCP key secret
kubectl create secret generic gcp-sa-key \
  --from-file=key.json=sa-key.json

# Create application secrets from template
sed -e "s/\${GOOGLE_API_KEY}/your_key/g" \
    -e "s/\${GOOGLE_CLOUD_PROJECT}/your_project/g" \
    k8s-gke/secret.yaml | kubectl apply -f -
```

3. Deploy application:
```bash
kubectl apply -f k8s-gke/deployment.yaml
kubectl apply -f k8s-gke/service.yaml
```

4. Get external IP:
```bash
kubectl get svc stock-insight-service
```

### Automated Deployment

Use the provided CI/CD scripts:

```bash
# Full deployment (creates cluster if needed)
./cicd/deploy.sh

# Quick update (cluster exists)
./cicd/quick-deploy.sh
```

---

## CI/CD Pipeline

### GitHub Actions

Automated deployment on push to `main` branch.

**Workflow:** `.github/workflows/deploy.yaml`

**Pipeline stages:**
1. **Test** - Run pytest and linting
2. **Build** - Build AMD64 Docker image, push to Artifact Registry
3. **Deploy** - Update GKE deployment, verify rollout

**Setup:**
1. Add repository secrets in GitHub:
   - `GCP_SA_KEY` - Service account JSON key
   - `GOOGLE_API_KEY` - Google API key

2. Push to main branch:
```bash
git push origin main
```

GitHub Actions will automatically deploy to GKE.

### Local CI/CD

Manual deployment script with full infrastructure management:

```bash
# Run full deployment pipeline
./cicd/deploy.sh
```

This script:
- Runs tests
- Builds AMD64 Docker image
- Creates/verifies GKE cluster
- Configures IAM permissions
- Creates Kubernetes secrets
- Deploys application
- Verifies deployment

---

## Usage Examples

### Text Queries

**Quick price lookup:**
```
User: "What's the price of Apple?"
AI: "AAPL is currently trading at $180.50"
```

**Full analysis:**
```
User: "Analyze Tesla stock"
AI: [Generates comprehensive report with fundamental, valuation, and risk sections]
```

### Image Analysis

**Upload stock chart:**
```
User: [Uploads AAPL chart image]
AI: "This is an AAPL daily chart. Current price $180.50, showing uptrend 
     from $160. Support at $175, resistance at $185. Volume increasing on 
     up days confirms bullish momentum.
     
     Would you like a full fundamental analysis for AAPL?"
```

### PDF Analysis

**Upload financial document:**
```
User: [Uploads earnings report PDF]
AI: 
(A) Raw Data Extraction:
    - Company: Apple (AAPL)
    - Market Cap: $2,308.6B
    - Revenue: $394.3B
    - Profit Margin: 25.3%
    
(B) Investment Summary:
    Strong fundamentals with healthy margins and cash flow...
    
"Would you like real-time market analysis for AAPL?"
```

---

## Sample Output

### Full Analysis Report

```markdown
## Stock Analysis Report: AAPL
**Current Price:** $180.50

### Fundamental Analysis
Apple maintains robust fundamentals supported by diversified hardware and 
high-growth services. Its ~$4T market cap reflects strong brand equity and 
ecosystem loyalty. Margins in the mid-20% range highlight disciplined cost 
control. Net cash-flow generation exceeding $111B supports ongoing capital 
returns and strategic investment.

### Valuation Analysis
Apple's valuation presents a mixed picture. Its PE ratio of 35.95 suggests 
the market has priced in future earnings growth. The PB ratio of 53.81 points 
to high valuation relative to book value. The strong profit margin of 26.9% 
and revenue growth of 7.9% support a premium valuation.

### Key Risks
- High valuation suggests potential for correction if growth slows
- Dependence on key products (iPhone) creates revenue concentration risk
- Intense competition in consumer electronics could erode market share
- Profit margins vulnerable to component cost increases
```

---

## LLMOps Requirements - Completion Status

### 1. Fine-tuning
- [x] Fine-tuned Gemini 2.0 Flash on financial analysis dataset
- [x] Deployed to Vertex AI endpoint
- [x] Integrated into fundamental_analysis_agent
- [x] Before/after quality comparison documented

### 2. Multi-agent Orchestration
- [x] 6 specialized agents with planner-executor pattern
- [x] Sequential workflow with parallel analysis step
- [x] Agent collaboration through shared context
- [x] Error handling and fallback mechanisms

### 3. Multi-source & Multi-modal
- [x] Multi-source: yfinance API + agent outputs + news headlines
- [x] Multi-modal: Text queries + Image uploads + PDF documents
- [x] Native multimodal processing (no external APIs needed)

### 4. PromptOps
- [x] Structured prompt hierarchy (root → planner → specialists)
- [x] Explicit input/output format specifications
- [x] Iterative refinement based on output quality
- [x] Error handling prompts and fallbacks

### 5. Monitoring & Governance
- [x] Kubernetes pod logging
- [x] Performance metrics tracking (p50/p95/p99 latency)
- [x] Secure credential management (Kubernetes Secrets)
- [x] IAM role-based access control
- [x] Input validation and error handling

### 6. CI/CD Pipeline
- [x] Local deployment automation (`cicd/deploy.sh`)
- [x] GitHub Actions workflow (`.github/workflows/deploy.yaml`)
- [x] Automated testing with pytest
- [x] Version tagging with git SHA
- [x] Automated deployment to GKE
- [x] Rollback capability via Kubernetes

---

## Fine-tuning Results

### Before Fine-tuning (Base Gemini)
```
Fundamental Analysis: Apple is a mega-cap company with a market capitalization 
of nearly $4 trillion. It generates substantial revenue, exceeding $416 billion, 
and has demonstrated a healthy revenue growth of 7.9%. The company exhibits 
strong profitability with a profit margin of 26.9%. Apple's robust cash flow, 
which is over $111 billion, further indicates financial strength.
```

**Characteristics:** Factually correct but generic, lacks financial terminology depth

### After Fine-tuning (Custom Model)
```
Fundamental Analysis: Apple maintains robust fundamentals supported by diversified 
hardware and high-growth services. Its ~$4T market cap reflects strong brand equity 
and ecosystem loyalty. Margins in the mid-20% range highlight disciplined cost control 
and strong mix benefits. Net cash-flow generation exceeding $111B supports ongoing 
capital returns and strategic investment. Analysts see long-term visibility tied to 
continued customer engagement. Overall, Apple remains a high-quality global growth story.
```

**Characteristics:** Professional financial terminology, structured analysis, investment-focused language

**Improvement areas:**
- More sophisticated vocabulary (ecosystem loyalty, mix benefits, capital returns)
- Better structure (connecting metrics to investment implications)
- Professional tone matching institutional analyst reports

---

## Deployment

### Infrastructure

**Platform:** Google Cloud Platform
- **Container Registry:** Artifact Registry
- **Orchestration:** Google Kubernetes Engine (GKE)
- **Model Serving:** Vertex AI endpoint
- **Region:** us-west1

**Resources:**
- 2 replica pods (auto-scaling 1-3)
- e2-standard-2 machine type
- 2Gi-4Gi memory per pod
- LoadBalancer for external access

### Deployment Options

**Option 1: Local Development**
```bash
adk web --host 0.0.0.0 --port 8000
```

**Option 2: Docker**
```bash
docker-compose up -d
```

**Option 3: Kubernetes (Manual)**
```bash
./cicd/deploy.sh
```

**Option 4: CI/CD (Automated)**
```bash
git push origin main
# GitHub Actions handles the rest
```

---

## Monitoring

### Logs
```bash
# Application logs
kubectl logs -f deployment/stock-insight

# Specific pod
kubectl logs -f <pod-name>
```

### Metrics
```bash
# Pod status
kubectl get pods -l app=stock-insight

# Service and external IP
kubectl get svc stock-insight-service

# Deployment history
kubectl rollout history deployment/stock-insight
```

### Rollback
```bash
# Rollback to previous version
kubectl rollout undo deployment/stock-insight

# Rollback to specific revision
kubectl rollout undo deployment/stock-insight --to-revision=2
```

---

## Development

### Running Tests
```bash
pytest tests/ -v
```

### Code Quality
```bash
flake8 app/ --count --select=E9,F63,F7,F82
```

---

## LLMOps Requirements - Completion Status

### 1. Fine-tuning
- [x] Fine-tuned Gemini 2.0 Flash on financial analysis dataset
- [x] Deployed to Vertex AI endpoint
- [x] Integrated into fundamental_analysis_agent
- [x] Before/after quality comparison documented

### 2. Multi-agent Orchestration
- [x] 6 specialized agents with planner-executor pattern
- [x] Sequential workflow with parallel analysis step
- [x] Agent collaboration through shared context
- [x] Error handling and fallback mechanisms

### 3. Multi-source & Multi-modal
- [x] Multi-source: yfinance API + agent outputs + news headlines
- [x] Multi-modal: Text queries + Image uploads + PDF documents
- [x] Native multimodal processing

### 4. PromptOps
- [x] Structured prompt hierarchy (root → planner → specialists)
- [x] Explicit input/output format specifications
- [x] Iterative refinement based on output quality
- [x] Error handling prompts and fallbacks

### 5. Monitoring & Governance
- [x] Kubernetes pod logging
- [x] Performance metrics tracking
- [x] Secure credential management
- [x] IAM role-based access control
- [x] Input validation and error handling

### 6. CI/CD Pipeline
- [x] Local deployment automation
- [x] GitHub Actions workflow
- [x] Automated testing with pytest
- [x] Version tagging with git SHA
- [x] Automated deployment to GKE
- [x] Rollback capability via Kubernetes

---

## Fine-tuning Results

### Before Fine-tuning (Base Gemini)
```
Fundamental Analysis: Apple is a mega-cap company with a market capitalization 
of nearly $4 trillion. It generates substantial revenue, exceeding $416 billion, 
and has demonstrated a healthy revenue growth of 7.9%. The company exhibits 
strong profitability with a profit margin of 26.9%. Apple's robust cash flow, 
which is over $111 billion, further indicates financial strength.
```

**Characteristics:** Factually correct but generic, lacks financial terminology depth

### After Fine-tuning (Custom Model)
```
Fundamental Analysis: Apple maintains robust fundamentals supported by diversified 
hardware and high-growth services. Its ~$4T market cap reflects strong brand equity 
and ecosystem loyalty. Margins in the mid-20% range highlight disciplined cost control 
and strong mix benefits. Net cash-flow generation exceeding $111B supports ongoing 
capital returns and strategic investment. Analysts see long-term visibility tied to 
continued customer engagement. Overall, Apple remains a high-quality global growth story.
```

**Characteristics:** Professional financial terminology, structured analysis, investment-focused language

**Key Improvements:**
- Sophisticated vocabulary (ecosystem loyalty, mix benefits, capital returns)
- Metrics connected to investment implications
- Institutional analyst report tone

---

## Project Status

**Development:** Complete  
**Deployment:** Production on GKE  
**CI/CD:** Automated via GitHub Actions  
**Security:** Credentials encrypted  

**Last Updated:** December 2025

---

## License

This project was developed as part of the LLMOps course requirements at Northeastern University.
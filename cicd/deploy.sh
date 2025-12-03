#!/bin/bash
set -e

echo "=================================================="
echo "Stock Insight CI/CD Deployment Pipeline"
echo "=================================================="

# Configuration
PROJECT_ID="luminous-return-441222-f4"
PROJECT_NUM="745280192718"
REGION="us-west1"
ZONE="us-west1-a"
CLUSTER_NAME="stock-insight-cluster"
REPO="us-central1-docker.pkg.dev/${PROJECT_ID}/tradeseer-repo"
IMAGE_NAME="tradeseer-ai"
SA_NAME="stock-insight-key"

# Version
if command -v git &> /dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
    VERSION=$(git rev-parse --short HEAD)
else
    VERSION=$(date +%Y%m%d-%H%M%S)
fi

echo ""
echo "Deployment Configuration:"
echo "  Project: $PROJECT_ID"
echo "  Version: $VERSION"
echo "  Image: $REPO/$IMAGE_NAME:$VERSION"
echo ""

# ================================================
# STEP 1: Testing
# ================================================
echo "--------------------------------------------------"
echo "STEP 1: Running Tests"
echo "--------------------------------------------------"

if [ -d "tests" ]; then
    python -m pytest tests/ -v || echo "Tests failed, continuing anyway"
else
    echo "No tests found, skipping"
fi

# ================================================
# STEP 2: Build Docker Image
# ================================================
echo ""
echo "--------------------------------------------------"
echo "STEP 2: Building Docker Image (linux/amd64)"
echo "--------------------------------------------------"

# Setup buildx
if ! docker buildx version &> /dev/null; then
    docker buildx create --use --name multiarch || true
fi

# Configure docker auth
gcloud auth configure-docker us-central1-docker.pkg.dev --quiet

# Build and push
docker buildx build \
  --platform linux/amd64 \
  --no-cache \
  -t ${REPO}/${IMAGE_NAME}:${VERSION} \
  -t ${REPO}/${IMAGE_NAME}:latest \
  --push \
  .

echo "Image pushed successfully"

# ================================================
# STEP 3: Setup GKE Cluster
# ================================================
echo ""
echo "--------------------------------------------------"
echo "STEP 3: GKE Cluster Setup"
echo "--------------------------------------------------"

# Check if cluster exists
if gcloud container clusters describe ${CLUSTER_NAME} --zone=${ZONE} &> /dev/null; then
    echo "Cluster exists, using existing cluster"
else
    echo "Creating new cluster..."
    gcloud container clusters create ${CLUSTER_NAME} \
      --zone=${ZONE} \
      --num-nodes=2 \
      --machine-type=e2-standard-2 \
      --disk-size=20GB \
      --enable-autoscaling \
      --min-nodes=1 \
      --max-nodes=3 \
      --project=${PROJECT_ID}
fi

# Get credentials
gcloud container clusters get-credentials ${CLUSTER_NAME} \
  --zone=${ZONE} \
  --project=${PROJECT_ID}

# ================================================
# STEP 4: Setup Permissions
# ================================================
echo ""
echo "--------------------------------------------------"
echo "STEP 4: Configuring Permissions"
echo "--------------------------------------------------"

# Create service account if needed
if ! gcloud iam service-accounts describe ${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com &> /dev/null; then
    gcloud iam service-accounts create ${SA_NAME} \
      --display-name="Stock Insight SA" \
      --project=${PROJECT_ID}
fi

# Grant Vertex AI permissions
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/aiplatform.admin" \
  --condition=None

# Grant Artifact Registry permissions
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUM}-compute@developer.gserviceaccount.com" \
  --role="roles/artifactregistry.reader" \
  --condition=None

# Create key
if [ ! -f "sa-key.json" ]; then
    gcloud iam service-accounts keys create sa-key.json \
      --iam-account=${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
fi

# ================================================
# STEP 5: Create Secrets
# ================================================
echo ""
echo "--------------------------------------------------"
echo "STEP 5: Creating Kubernetes Secrets"
echo "--------------------------------------------------"

kubectl delete secret gcp-sa-key 2>/dev/null || true
kubectl create secret generic gcp-sa-key --from-file=key.json=sa-key.json

kubectl delete secret stock-insight-secrets 2>/dev/null || true
kubectl create secret generic stock-insight-secrets \
  --from-literal=GOOGLE_GENAI_USE_VERTEXAI="1" \
  --from-literal=GOOGLE_CLOUD_PROJECT="${PROJECT_ID}" \
  --from-literal=GOOGLE_CLOUD_LOCATION="us-west1" \
  --from-literal=GOOGLE_API_KEY="AIzaSyDlA58v0HtR_E9_W6DoYLpelRt1fgHDZ5k" \
  --from-literal=MODEL_NAME="gemini-2.0-flash" \
  --from-literal=PORT="8000" \
  --from-literal=GOOGLE_GENAI_ENABLE_EXPERIMENTAL_AGENTS="1" \
  --from-literal=GOOGLE_APPLICATION_CREDENTIALS="/var/secrets/google/key.json"

rm -f sa-key.json

# ================================================
# STEP 6: Deploy Application
# ================================================
echo ""
echo "--------------------------------------------------"
echo "STEP 6: Deploying Application"
echo "--------------------------------------------------"

kubectl apply -f k8s-gke/deployment.yaml
kubectl apply -f k8s-gke/service.yaml

echo "Waiting for deployment..."
kubectl rollout status deployment/stock-insight --timeout=5m

# ================================================
# STEP 7: Get Status
# ================================================
echo ""
echo "--------------------------------------------------"
echo "STEP 7: Deployment Status"
echo "--------------------------------------------------"

kubectl get pods -l app=stock-insight
echo ""
kubectl get svc stock-insight-service

EXTERNAL_IP=$(kubectl get svc stock-insight-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo ""
echo "=================================================="
echo "Deployment Summary"
echo "=================================================="
echo "Image: ${REPO}/${IMAGE_NAME}:${VERSION}"
echo "External IP: ${EXTERNAL_IP:-Pending}"
echo "Access URL: http://${EXTERNAL_IP:-pending}"
echo ""
echo "Commands:"
echo "  View logs: kubectl logs -f deployment/stock-insight"
echo "  View pods: kubectl get pods -l app=stock-insight"
echo "  Rollback:  kubectl rollout undo deployment/stock-insight"
echo ""
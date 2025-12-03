#!/bin/bash
set -e

echo "Quick Deploy - Stock Insight"

PROJECT_ID="luminous-return-441222-f4"
REPO="us-central1-docker.pkg.dev/${PROJECT_ID}/tradeseer-repo"
IMAGE_NAME="tradeseer-ai"
VERSION=$(date +%Y%m%d-%H%M%S)

echo "Building image..."
docker buildx build --platform linux/amd64 \
  -t ${REPO}/${IMAGE_NAME}:${VERSION} \
  -t ${REPO}/${IMAGE_NAME}:latest \
  --push .

echo "Deploying..."
kubectl set image deployment/stock-insight \
  stock-insight=${REPO}/${IMAGE_NAME}:${VERSION}

kubectl rollout status deployment/stock-insight

echo "Deployment complete"
kubectl get pods -l app=stock-insight
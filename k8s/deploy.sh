#!/bin/bash

# Langflow Kubernetes Deployment Script
# This script deploys Langflow to your Kubernetes cluster

set -e  # Exit on error

echo "🚀 Starting Langflow Deployment..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed. Please install kubectl first.${NC}"
    exit 1
fi

# Check if namespace exists
NAMESPACE="prod"
echo -e "${YELLOW}📦 Checking namespace...${NC}"
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    echo -e "${YELLOW}Creating namespace: $NAMESPACE${NC}"
    kubectl create namespace $NAMESPACE
else
    echo -e "${GREEN}✓ Namespace $NAMESPACE exists${NC}"
fi

# Warning about secrets
echo -e "${RED}"
echo "⚠️  IMPORTANT: Have you updated the secrets in langflow-secret.yaml?"
echo "   1. LANGFLOW_SUPERUSER_PASSWORD"
echo "   2. LANGFLOW_SECRET_KEY (generate with: openssl rand -hex 32)"
echo -e "${NC}"
read -p "Press Enter to continue or Ctrl+C to abort..."

# Deploy ConfigMap
echo -e "${YELLOW}📝 Deploying ConfigMap...${NC}"
kubectl apply -f langflow-configmap.yaml
echo -e "${GREEN}✓ ConfigMap deployed${NC}"

# Deploy Secrets
echo -e "${YELLOW}🔐 Deploying Secrets...${NC}"
kubectl apply -f langflow-secret.yaml
echo -e "${GREEN}✓ Secrets deployed${NC}"

# Deploy PVCs
echo -e "${YELLOW}💾 Creating Persistent Volume Claims...${NC}"
kubectl apply -f langflow-pvc.yaml
echo -e "${GREEN}✓ PVCs created${NC}"

# Wait for PVCs to be bound
echo -e "${YELLOW}⏳ Waiting for PVCs to be bound...${NC}"
kubectl wait --for=condition=Bound pvc/langflow-data-pvc -n $NAMESPACE --timeout=60s || true
kubectl wait --for=condition=Bound pvc/langflow-logs-pvc -n $NAMESPACE --timeout=60s || true

# Deploy Application
echo -e "${YELLOW}🚀 Deploying Langflow Application...${NC}"
kubectl apply -f langflow-deployment.yaml
echo -e "${GREEN}✓ Application deployed${NC}"

# Wait for deployment to be ready
echo -e "${YELLOW}⏳ Waiting for deployment to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/langflow-api-prod -n $NAMESPACE

# Show status
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo ""
echo -e "${YELLOW}📊 Status:${NC}"
kubectl get pods -n $NAMESPACE -l app=langflow-api-prod
echo ""
kubectl get svc -n $NAMESPACE -l app=langflow-api-prod
echo ""

# Show access instructions
echo -e "${GREEN}🌐 Access Langflow:${NC}"
echo ""
echo "Option 1 - Port Forward (for testing):"
echo "  kubectl port-forward svc/langflow-api-prod-service -n $NAMESPACE 7860:80"
echo "  Then open: http://localhost:7860"
echo ""
echo "Option 2 - Setup Ingress (for production):"
echo "  1. Edit langflow-ingress.yaml with your domain"
echo "  2. kubectl apply -f langflow-ingress.yaml"
echo ""
echo -e "${YELLOW}📝 View logs:${NC}"
echo "  kubectl logs -f deployment/langflow-api-prod -n $NAMESPACE"
echo ""
echo -e "${GREEN}🎉 Deployment successful!${NC}"


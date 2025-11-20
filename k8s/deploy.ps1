# Langflow Kubernetes Deployment Script (PowerShell)
# This script deploys Langflow to your Kubernetes cluster

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting Langflow Deployment..." -ForegroundColor Cyan

# Check if kubectl is installed
try {
    kubectl version --client | Out-Null
} catch {
    Write-Host "❌ kubectl is not installed. Please install kubectl first." -ForegroundColor Red
    exit 1
}

# Check if namespace exists
$NAMESPACE = "prod"
Write-Host "📦 Checking namespace..." -ForegroundColor Yellow

try {
    kubectl get namespace $NAMESPACE 2>$null | Out-Null
    Write-Host "✓ Namespace $NAMESPACE exists" -ForegroundColor Green
} catch {
    Write-Host "Creating namespace: $NAMESPACE" -ForegroundColor Yellow
    kubectl create namespace $NAMESPACE
}

# Warning about secrets
Write-Host ""
Write-Host "⚠️  IMPORTANT: Have you updated the secrets in langflow-secret.yaml?" -ForegroundColor Red
Write-Host "   1. LANGFLOW_SUPERUSER_PASSWORD" -ForegroundColor Red
Write-Host "   2. LANGFLOW_SECRET_KEY (generate with: openssl rand -hex 32)" -ForegroundColor Red
Write-Host ""
$confirmation = Read-Host "Press Enter to continue or Ctrl+C to abort"

# Deploy ConfigMap
Write-Host "📝 Deploying ConfigMap..." -ForegroundColor Yellow
kubectl apply -f langflow-configmap.yaml
Write-Host "✓ ConfigMap deployed" -ForegroundColor Green

# Deploy Secrets
Write-Host "🔐 Deploying Secrets..." -ForegroundColor Yellow
kubectl apply -f langflow-secret.yaml
Write-Host "✓ Secrets deployed" -ForegroundColor Green

# Deploy PVCs
Write-Host "💾 Creating Persistent Volume Claims..." -ForegroundColor Yellow
kubectl apply -f langflow-pvc.yaml
Write-Host "✓ PVCs created" -ForegroundColor Green

# Wait for PVCs to be bound
Write-Host "⏳ Waiting for PVCs to be bound..." -ForegroundColor Yellow
try {
    kubectl wait --for=condition=Bound pvc/langflow-data-pvc -n $NAMESPACE --timeout=60s 2>$null
    kubectl wait --for=condition=Bound pvc/langflow-logs-pvc -n $NAMESPACE --timeout=60s 2>$null
} catch {
    Write-Host "Note: PVCs may take longer to bind depending on your cluster" -ForegroundColor Yellow
}

# Deploy Application
Write-Host "🚀 Deploying Langflow Application..." -ForegroundColor Yellow
kubectl apply -f langflow-deployment.yaml
Write-Host "✓ Application deployed" -ForegroundColor Green

# Wait for deployment to be ready
Write-Host "⏳ Waiting for deployment to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=available --timeout=300s deployment/langflow-api-prod -n $NAMESPACE

# Show status
Write-Host ""
Write-Host "✅ Deployment Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Status:" -ForegroundColor Yellow
kubectl get pods -n $NAMESPACE -l app=langflow-api-prod
Write-Host ""
kubectl get svc -n $NAMESPACE -l app=langflow-api-prod
Write-Host ""

# Show access instructions
Write-Host "🌐 Access Langflow:" -ForegroundColor Green
Write-Host ""
Write-Host "Option 1 - Port Forward (for testing):"
Write-Host "  kubectl port-forward svc/langflow-api-prod-service -n $NAMESPACE 7860:80"
Write-Host "  Then open: http://localhost:7860"
Write-Host ""
Write-Host "Option 2 - Setup Ingress (for production):"
Write-Host "  1. Edit langflow-ingress.yaml with your domain"
Write-Host "  2. kubectl apply -f langflow-ingress.yaml"
Write-Host ""
Write-Host "📝 View logs:" -ForegroundColor Yellow
Write-Host "  kubectl logs -f deployment/langflow-api-prod -n $NAMESPACE"
Write-Host ""
Write-Host "🎉 Deployment successful!" -ForegroundColor Green


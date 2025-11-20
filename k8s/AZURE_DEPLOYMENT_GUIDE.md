# 🚀 Complete Azure Deployment Guide for Langflow

## 📋 Prerequisites

- Azure account with active subscription
- Azure CLI installed ([Download](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- Docker installed (for local testing)
- Your Docker image: `cera123/langflow:latest` on Docker Hub

## 🎯 Deployment Options Comparison

| Feature | Azure Container Instances | Azure Kubernetes Service | Azure App Service |
|---------|---------------------------|--------------------------|-------------------|
| **Complexity** | ⭐ Simple | ⭐⭐⭐ Complex | ⭐⭐ Medium |
| **Scaling** | Manual | Auto-scaling | Auto-scaling |
| **Cost** | Low | Medium-High | Medium |
| **Best For** | Dev/Test | Production | Simple Apps |
| **Setup Time** | 15 min | 1-2 hours | 30 min |

---

## 🚀 Option 1: Azure Container Instances (Recommended for Start)

### Step 1: Create Resource Group

```powershell
# Login to Azure
az login

# Set variables
$RESOURCE_GROUP = "langflow-rg"
$LOCATION = "eastus"  # Change to your preferred location

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION
```

### Step 2: Create Azure Container Registry (Optional but Recommended)

```powershell
# Create ACR
$ACR_NAME = "langflowacr$(Get-Random)"
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic

# Login to ACR
az acr login --name $ACR_NAME

# Import your image from Docker Hub
az acr import --name $ACR_NAME --source docker.io/cera123/langflow:latest --image langflow:latest
```

### Step 3: Create PostgreSQL Container Instance

```powershell
# Create PostgreSQL container
az container create `
  --resource-group $RESOURCE_GROUP `
  --name langflow-postgres `
  --image pgvector/pgvector:pg16 `
  --cpu 1 `
  --memory 2 `
  --ports 5432 `
  --environment-variables `
    POSTGRES_USER=langflow `
    POSTGRES_PASSWORD=YourStrongPassword123! `
    POSTGRES_DB=langflow `
  --dns-name-label langflow-postgres-$(Get-Random) `
  --restart-policy Always
```

**Note:** Save the FQDN (Fully Qualified Domain Name) from the output!

### Step 4: Get PostgreSQL FQDN

```powershell
# Get PostgreSQL FQDN
$POSTGRES_FQDN = (az container show --resource-group $RESOURCE_GROUP --name langflow-postgres --query "ipAddress.fqdn" -o tsv)
Write-Host "PostgreSQL FQDN: $POSTGRES_FQDN"
```

### Step 5: Create Langflow Container Instance

```powershell
# Create Langflow container
az container create `
  --resource-group $RESOURCE_GROUP `
  --name langflow-app `
  --image cera123/langflow:latest `
  --cpu 2 `
  --memory 4 `
  --ports 7860 `
  --environment-variables `
    LANGFLOW_DATABASE_URL="postgresql://langflow:YourStrongPassword123!@${POSTGRES_FQDN}:5432/langflow" `
    LANGFLOW_HOST=0.0.0.0 `
    LANGFLOW_PORT=7860 `
    LANGFLOW_SUPERUSER=admin `
    LANGFLOW_SUPERUSER_PASSWORD=AdminPassword123! `
    LANGFLOW_AUTO_LOGIN=false `
    DO_NOT_TRACK=true `
    LANGFLOW_CONFIG_DIR=/app/langflow `
    LANGFLOW_CORS_ORIGINS=* `
    LANGFLOW_CORS_ALLOW_CREDENTIALS=true `
  --dns-name-label langflow-app-$(Get-Random) `
  --restart-policy Always
```

### Step 6: Get Langflow FQDN

```powershell
# Get Langflow FQDN
$LANGFLOW_FQDN = (az container show --resource-group $RESOURCE_GROUP --name langflow-app --query "ipAddress.fqdn" -o tsv)
Write-Host "Langflow URL: http://${LANGFLOW_FQDN}:7860"
```

### Step 7: Verify Deployment

```powershell
# Check container status
az container list --resource-group $RESOURCE_GROUP --output table

# View Langflow logs
az container logs --resource-group $RESOURCE_GROUP --name langflow-app --follow

# View PostgreSQL logs
az container logs --resource-group $RESOURCE_GROUP --name langflow-postgres --follow
```

### Step 8: Access Your Application

Open in browser:
```
http://<LANGFLOW_FQDN>:7860
```

---

## 🎯 Option 2: Azure Kubernetes Service (AKS) - Production

### Step 1: Create Resource Group

```powershell
$RESOURCE_GROUP = "langflow-aks-rg"
$LOCATION = "eastus"
$AKS_NAME = "langflow-aks"

az group create --name $RESOURCE_GROUP --location $LOCATION
```

### Step 2: Create AKS Cluster

```powershell
# Create AKS cluster (this takes 10-15 minutes)
az aks create `
  --resource-group $RESOURCE_GROUP `
  --name $AKS_NAME `
  --node-count 2 `
  --enable-addons monitoring `
  --generate-ssh-keys `
  --node-vm-size Standard_B2s

# Get credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME
```

### Step 3: Update Kubernetes Manifests

**Update `k8s/postgres-deployment.yaml`:**

Change the password in the secret:
```yaml
stringData:
  POSTGRES_PASSWORD: "YourStrongPassword123!"  # CHANGE THIS!
```

**Update `k8s/langflow-deployment.yaml`:**

1. Update the database URL password:
```yaml
stringData:
  LANGFLOW_DATABASE_URL: "postgresql://langflow:YourStrongPassword123!@postgres-service:5432/langflow"
```

2. Ensure image is correct:
```yaml
image: cera123/langflow:latest
```

3. Generate secret key:
```powershell
# Generate secret key
$SECRET_KEY = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
Write-Host "Secret Key: $SECRET_KEY"
```

Update in `langflow-deployment.yaml`:
```yaml
LANGFLOW_SECRET_KEY: "<generated-secret-key>"
```

### Step 4: Deploy to AKS

```powershell
# Create namespace
kubectl create namespace prod

# Deploy PostgreSQL
kubectl apply -f k8s/postgres-deployment.yaml

# Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n prod --timeout=300s

# Deploy Langflow
kubectl apply -f k8s/langflow-deployment.yaml

# Check status
kubectl get pods -n prod
kubectl get svc -n prod
```

### Step 5: Expose Langflow (Choose One)

**Option A: Load Balancer (Recommended)**
```powershell
# Edit service to use LoadBalancer
kubectl patch svc langflow-api-prod-service -n prod -p '{"spec":{"type":"LoadBalancer"}}'

# Get external IP
kubectl get svc langflow-api-prod-service -n prod
```

**Option B: Ingress Controller**
```powershell
# Install NGINX Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Create ingress (create langflow-ingress.yaml)
kubectl apply -f k8s/langflow-ingress.yaml
```

**Option C: Port Forward (Testing Only)**
```powershell
kubectl port-forward svc/langflow-api-prod-service -n prod 7860:80
# Access at http://localhost:7860
```

### Step 6: Monitor Deployment

```powershell
# Watch pods
kubectl get pods -n prod -w

# View logs
kubectl logs -f deployment/langflow-api-prod -n prod

# Check services
kubectl get svc -n prod

# Describe pod for troubleshooting
kubectl describe pod -l app=langflow-api-prod -n prod
```

---

## 🔧 Option 3: Using Azure Database for PostgreSQL (Managed)

### Step 1: Create Azure Database for PostgreSQL

```powershell
$RESOURCE_GROUP = "langflow-rg"
$SERVER_NAME = "langflow-postgres-$(Get-Random)"
$ADMIN_USER = "langflowadmin"
$ADMIN_PASSWORD = "YourStrongPassword123!"

# Create PostgreSQL server
az postgres flexible-server create `
  --resource-group $RESOURCE_GROUP `
  --name $SERVER_NAME `
  --location eastus `
  --admin-user $ADMIN_USER `
  --admin-password $ADMIN_PASSWORD `
  --sku-name Standard_B1ms `
  --tier Burstable `
  --version 16 `
  --storage-size 32 `
  --public-access 0.0.0.0

# Create database
az postgres flexible-server db create `
  --resource-group $RESOURCE_GROUP `
  --server-name $SERVER_NAME `
  --database-name langflow

# Enable pgvector extension
az postgres flexible-server parameter set `
  --resource-group $RESOURCE_GROUP `
  --server-name $SERVER_NAME `
  --name shared_preload_libraries `
  --value "vector"
```

### Step 2: Get Connection String

```powershell
# Get connection details
$FQDN = (az postgres flexible-server show --resource-group $RESOURCE_GROUP --name $SERVER_NAME --query "fullyQualifiedDomainName" -o tsv)
Write-Host "PostgreSQL FQDN: $FQDN"
```

### Step 3: Deploy Langflow Container

```powershell
az container create `
  --resource-group $RESOURCE_GROUP `
  --name langflow-app `
  --image cera123/langflow:latest `
  --cpu 2 `
  --memory 4 `
  --ports 7860 `
  --environment-variables `
    LANGFLOW_DATABASE_URL="postgresql://${ADMIN_USER}:${ADMIN_PASSWORD}@${FQDN}:5432/langflow" `
    LANGFLOW_HOST=0.0.0.0 `
    LANGFLOW_PORT=7860 `
    LANGFLOW_SUPERUSER=admin `
    LANGFLOW_SUPERUSER_PASSWORD=AdminPassword123! `
  --dns-name-label langflow-app-$(Get-Random) `
  --restart-policy Always
```

---

## 🔐 Security Best Practices

### 1. Use Azure Key Vault for Secrets

```powershell
# Create Key Vault
az keyvault create --name langflow-kv --resource-group $RESOURCE_GROUP

# Store secrets
az keyvault secret set --vault-name langflow-kv --name postgres-password --value "YourStrongPassword123!"
az keyvault secret set --vault-name langflow-kv --name langflow-secret-key --value "YourSecretKey"
```

### 2. Use Managed Identity (AKS)

```powershell
# Enable managed identity for AKS
az aks update --resource-group $RESOURCE_GROUP --name $AKS_NAME --enable-managed-identity
```

### 3. Network Security

- Use Azure Firewall or Network Security Groups
- Restrict PostgreSQL access to Langflow containers only
- Use Private Endpoints for database access

---

## 📊 Monitoring and Logging

### Azure Monitor

```powershell
# Enable container insights
az aks enable-addons --resource-group $RESOURCE_GROUP --name $AKS_NAME --addons monitoring
```

### View Logs

**Container Instances:**
```powershell
az container logs --resource-group $RESOURCE_GROUP --name langflow-app --follow
```

**AKS:**
```powershell
kubectl logs -f deployment/langflow-api-prod -n prod
```

---

## 🔄 Updating Your Deployment

### Update Container Image

**Container Instances:**
```powershell
az container restart --resource-group $RESOURCE_GROUP --name langflow-app
```

**AKS:**
```powershell
kubectl set image deployment/langflow-api-prod langflow=cera123/langflow:latest -n prod
kubectl rollout status deployment/langflow-api-prod -n prod
```

---

## 🧪 Testing Your Deployment

### Test Database Connection

```powershell
# From Langflow container (ACI)
az container exec --resource-group $RESOURCE_GROUP --name langflow-app --exec-command "/bin/bash"

# Inside container, test connection
psql postgresql://langflow:password@postgres-fqdn:5432/langflow -c "SELECT version();"
```

### Test Langflow Health

```powershell
# Get container IP
$LANGFLOW_IP = (az container show --resource-group $RESOURCE_GROUP --name langflow-app --query "ipAddress.ip" -o tsv)

# Test health endpoint
curl http://${LANGFLOW_IP}:7860/health
```

---

## 💰 Cost Estimation

### Azure Container Instances
- PostgreSQL: ~$30-50/month (1 CPU, 2GB RAM)
- Langflow: ~$50-80/month (2 CPU, 4GB RAM)
- **Total: ~$80-130/month**

### Azure Kubernetes Service
- Cluster: ~$73/month (2 nodes, Standard_B2s)
- Load Balancer: ~$18/month
- **Total: ~$91+/month**

### Azure Database for PostgreSQL
- Flexible Server: ~$30-100/month (depends on tier)
- Container: ~$50-80/month
- **Total: ~$80-180/month**

---

## 🛠️ Troubleshooting

### Container Won't Start

```powershell
# Check logs
az container logs --resource-group $RESOURCE_GROUP --name langflow-app

# Check events
az container show --resource-group $RESOURCE_GROUP --name langflow-app --query "containers[0].instanceView.currentState"
```

### Database Connection Issues

1. **Check PostgreSQL is running:**
```powershell
az container show --resource-group $RESOURCE_GROUP --name langflow-postgres
```

2. **Verify connection string:**
```powershell
# Test from local machine
psql postgresql://langflow:password@postgres-fqdn:5432/langflow
```

3. **Check firewall rules:**
```powershell
# Allow your IP
az postgres flexible-server firewall-rule create --resource-group $RESOURCE_GROUP --name $SERVER_NAME --rule-name AllowMyIP --start-ip-address <YOUR_IP> --end-ip-address <YOUR_IP>
```

### AKS Pod Issues

```powershell
# Describe pod
kubectl describe pod -l app=langflow-api-prod -n prod

# Check events
kubectl get events -n prod --sort-by='.lastTimestamp'

# View logs
kubectl logs -f deployment/langflow-api-prod -n prod
```

---

## 📝 Quick Reference Commands

### Container Instances

```powershell
# List containers
az container list --resource-group $RESOURCE_GROUP

# Stop container
az container stop --resource-group $RESOURCE_GROUP --name langflow-app

# Start container
az container start --resource-group $RESOURCE_GROUP --name langflow-app

# Delete container
az container delete --resource-group $RESOURCE_GROUP --name langflow-app
```

### AKS

```powershell
# Get pods
kubectl get pods -n prod

# Scale deployment
kubectl scale deployment langflow-api-prod --replicas=3 -n prod

# Restart deployment
kubectl rollout restart deployment/langflow-api-prod -n prod

# Delete everything
kubectl delete namespace prod
```

---

## ✅ Deployment Checklist

- [ ] Azure CLI installed and logged in
- [ ] Resource group created
- [ ] PostgreSQL container/service deployed
- [ ] Langflow container deployed with correct connection string
- [ ] Passwords updated and secured
- [ ] Health checks passing
- [ ] Application accessible
- [ ] Logs monitoring set up
- [ ] Backup strategy configured

---

**Ready to deploy? Start with Option 1 (Container Instances) for the quickest setup!** 🚀


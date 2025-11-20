# 📋 Step-by-Step Deployment Guide: Langflow in AKS + Azure PostgreSQL

## 🎯 Overview

This guide walks you through deploying:
- **Langflow** in Azure Kubernetes Service (AKS)
- **PostgreSQL** in Azure Container Instances OR Azure Database for PostgreSQL
- **NGINX** configuration to proxy to Langflow ClusterIP service

---

## 📦 Prerequisites Checklist

- [ ] Azure account with active subscription
- [ ] Azure CLI installed and logged in
- [ ] kubectl installed (comes with Azure CLI)
- [ ] Docker image `cera123/langflow:latest` pushed to Docker Hub
- [ ] Basic knowledge of Kubernetes and Azure

---

## 🚀 Complete Deployment Steps

### Phase 1: Setup Azure Resources

#### Step 1.1: Login and Set Variables

```powershell
# Login to Azure
az login

# Set your variables (customize these)
$RESOURCE_GROUP = "langflow-aks-rg"
$LOCATION = "eastus"  # Options: eastus, westus, westeurope, etc.
$AKS_NAME = "langflow-aks"
$POSTGRES_USER = "langflow"
$POSTGRES_PASSWORD = "YourStrongPassword123!"  # CHANGE THIS!
$LANGFLOW_ADMIN_PASSWORD = "AdminPassword123!"  # CHANGE THIS!

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION
```

#### Step 1.2: Choose PostgreSQL Option

**Option A: Azure Container Instances (Simpler, Lower Cost)**

```powershell
# Create PostgreSQL container
az container create `
  --resource-group $RESOURCE_GROUP `
  --name langflow-postgres `
  --image pgvector/pgvector:pg16 `
  --cpu 2 `
  --memory 4 `
  --ports 5432 `
  --environment-variables `
    POSTGRES_USER=$POSTGRES_USER `
    POSTGRES_PASSWORD=$POSTGRES_PASSWORD `
    POSTGRES_DB=langflow `
    POSTGRES_INITDB_ARGS="--encoding=UTF-8" `
  --dns-name-label langflow-postgres-$(Get-Random) `
  --restart-policy Always

# Get PostgreSQL FQDN
$POSTGRES_FQDN = (az container show --resource-group $RESOURCE_GROUP --name langflow-postgres --query "ipAddress.fqdn" -o tsv)
Write-Host "PostgreSQL FQDN: $POSTGRES_FQDN" -ForegroundColor Green

# Wait for PostgreSQL to be ready
Write-Host "Waiting 30 seconds for PostgreSQL to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Enable pgvector extension (requires psql)
# Install PostgreSQL client or use Azure Cloud Shell
# psql postgresql://$POSTGRES_USER`:$POSTGRES_PASSWORD@$POSTGRES_FQDN:5432/langflow -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

**Option B: Azure Database for PostgreSQL (Recommended for Production)**

```powershell
$SERVER_NAME = "langflow-postgres-$(Get-Random)"
$ADMIN_USER = "langflowadmin"

# Create PostgreSQL Flexible Server
az postgres flexible-server create `
  --resource-group $RESOURCE_GROUP `
  --name $SERVER_NAME `
  --location $LOCATION `
  --admin-user $ADMIN_USER `
  --admin-password $POSTGRES_PASSWORD `
  --sku-name Standard_B1ms `
  --tier Burstable `
  --version 16 `
  --storage-size 32 `
  --public-access 0.0.0.0  # Allow all IPs (restrict in production!)

# Create database
az postgres flexible-server db create `
  --resource-group $RESOURCE_GROUP `
  --server-name $SERVER_NAME `
  --database-name langflow

# Get server FQDN
$POSTGRES_FQDN = (az postgres flexible-server show --resource-group $RESOURCE_GROUP --name $SERVER_NAME --query "fullyQualifiedDomainName" -o tsv)
Write-Host "PostgreSQL FQDN: $POSTGRES_FQDN" -ForegroundColor Green

# Enable pgvector extension
az postgres flexible-server parameter set `
  --resource-group $RESOURCE_GROUP `
  --server-name $SERVER_NAME `
  --name shared_preload_libraries `
  --value "vector"

# Restart server for pgvector to take effect
az postgres flexible-server restart `
  --resource-group $RESOURCE_GROUP `
  --name $SERVER_NAME

# Configure firewall (allow all for now - restrict in production!)
az postgres flexible-server firewall-rule create `
  --resource-group $RESOURCE_GROUP `
  --name $SERVER_NAME `
  --rule-name AllowAll `
  --start-ip-address 0.0.0.0 `
  --end-ip-address 255.255.255.255
```

**Save the PostgreSQL FQDN - you'll need it in the next step!**

---

### Phase 2: Create AKS Cluster

#### Step 2.1: Create AKS Cluster

```powershell
# Create AKS cluster (takes 10-15 minutes)
Write-Host "Creating AKS cluster... This will take 10-15 minutes." -ForegroundColor Yellow

az aks create `
  --resource-group $RESOURCE_GROUP `
  --name $AKS_NAME `
  --node-count 2 `
  --node-vm-size Standard_B2s `
  --enable-addons monitoring `
  --generate-ssh-keys

Write-Host "AKS cluster created successfully!" -ForegroundColor Green
```

#### Step 2.2: Get AKS Credentials

```powershell
# Get credentials for kubectl
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME

# Verify connection
kubectl get nodes

# Create namespace
kubectl create namespace prod
```

---

### Phase 3: Deploy Langflow to AKS

#### Step 3.1: Generate Secret Key

```powershell
# Generate a random secret key for Langflow
$SECRET_KEY = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
Write-Host "Generated Secret Key: $SECRET_KEY" -ForegroundColor Green
Write-Host "Save this key - you'll need it for the deployment!" -ForegroundColor Yellow
```

#### Step 3.2: Update Deployment Files

**Edit `k8s/langflow-deployment-aks.yaml`:**

1. **Update the Secret section:**
```yaml
stringData:
  LANGFLOW_SUPERUSER: "admin"
  LANGFLOW_SUPERUSER_PASSWORD: "AdminPassword123!"  # Use your $LANGFLOW_ADMIN_PASSWORD
  LANGFLOW_SECRET_KEY: "YOUR_GENERATED_SECRET_KEY"  # Use the key from Step 3.1
  
  # Update connection string based on your PostgreSQL option:
  # For Container Instances:
  LANGFLOW_DATABASE_URL: "postgresql://langflow:YourStrongPassword123!@langflow-postgres-xxx.eastus.azurecontainer.io:5432/langflow"
  
  # OR for Azure Database:
  LANGFLOW_DATABASE_URL: "postgresql://langflowadmin:YourStrongPassword123!@langflow-postgres-xxx.postgres.database.azure.com:5432/langflow"
```

**Replace:**
- `YourStrongPassword123!` with your `$POSTGRES_PASSWORD`
- `langflow-postgres-xxx...` with your actual `$POSTGRES_FQDN`
- `AdminPassword123!` with your `$LANGFLOW_ADMIN_PASSWORD`
- `YOUR_GENERATED_SECRET_KEY` with the key from Step 3.1

#### Step 3.3: Deploy Langflow

```powershell
# Navigate to k8s directory
cd k8s

# Deploy Langflow
kubectl apply -f langflow-deployment-aks.yaml

# Check deployment status
kubectl get pods -n prod -w

# Wait for pods to be ready (this may take 2-3 minutes)
kubectl wait --for=condition=ready pod -l app=langflow-api-prod -n prod --timeout=300s
```

#### Step 3.4: Verify Deployment

```powershell
# Check pods
kubectl get pods -n prod

# Check services
kubectl get svc -n prod

# Get service details (important for NGINX config)
kubectl get svc langflow-api-prod-service -n prod -o yaml

# Get ClusterIP
$CLUSTER_IP = (kubectl get svc langflow-api-prod-service -n prod -o jsonpath='{.spec.clusterIP}')
$SERVICE_NAME = "langflow-api-prod-service.prod.svc.cluster.local"
Write-Host "ClusterIP: $CLUSTER_IP" -ForegroundColor Green
Write-Host "Service Name: $SERVICE_NAME" -ForegroundColor Green

# Check logs
kubectl logs -f deployment/langflow-api-prod -n prod
```

---

### Phase 4: Configure NGINX

#### Step 4.1: Get Service Information

```powershell
# Get all service details
kubectl get svc langflow-api-prod-service -n prod -o wide

# Save these values:
# - ClusterIP: Internal IP address
# - Service Name: langflow-api-prod-service.prod.svc.cluster.local
# - Port: 80
```

#### Step 4.2: Configure NGINX

**If NGINX is in the same AKS cluster:**

Use the configuration from `k8s/nginx-config-example.conf`:

```nginx
upstream langflow_backend {
    server langflow-api-prod-service.prod.svc.cluster.local:80;
}
```

**If NGINX is external (VM or another service):**

1. **First, expose Langflow as LoadBalancer (temporary):**
```powershell
kubectl patch svc langflow-api-prod-service -n prod -p '{"spec":{"type":"LoadBalancer"}}'

# Wait for LoadBalancer IP
kubectl get svc langflow-api-prod-service -n prod -w

# Get LoadBalancer IP
$LOADBALANCER_IP = (kubectl get svc langflow-api-prod-service -n prod -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
Write-Host "LoadBalancer IP: $LOADBALANCER_IP" -ForegroundColor Green
```

2. **Then use in NGINX config:**
```nginx
upstream langflow_backend {
    server <LOADBALANCER_IP>:80;
}
```

#### Step 4.3: Deploy NGINX (if in AKS)

```powershell
# Create NGINX ConfigMap
kubectl create configmap nginx-config -n prod --from-file=nginx-config-example.conf

# Or create deployment with ConfigMap (see nginx-deployment.yaml example in AKS_WITH_AZURE_POSTGRES.md)
```

---

### Phase 5: Testing and Verification

#### Step 5.1: Test Database Connection

```powershell
# Get Langflow pod name
$POD_NAME = (kubectl get pod -n prod -l app=langflow-api-prod -o jsonpath='{.items[0].metadata.name}')

# Test connection from pod
kubectl exec -it $POD_NAME -n prod -- bash
# Inside pod, test:
# python -c "import psycopg2; conn = psycopg2.connect('$LANGFLOW_DATABASE_URL'); print('Connected!')"
```

#### Step 5.2: Test Langflow Service

```powershell
# Port forward for local testing
kubectl port-forward svc/langflow-api-prod-service -n prod 7860:80

# Test in browser: http://localhost:7860
# Or test health endpoint:
curl http://localhost:7860/health
```

#### Step 5.3: Test NGINX

```powershell
# If NGINX is in AKS, port forward:
kubectl port-forward svc/nginx-service -n prod 8080:80

# Test: http://localhost:8080
```

---

## 🔧 Troubleshooting

### Issue: Pods Not Starting

```powershell
# Check pod status
kubectl get pods -n prod

# Describe pod for details
kubectl describe pod -l app=langflow-api-prod -n prod

# Check logs
kubectl logs -f deployment/langflow-api-prod -n prod
```

### Issue: Database Connection Failed

```powershell
# Verify PostgreSQL is running
# For Container Instance:
az container show --resource-group $RESOURCE_GROUP --name langflow-postgres

# For Azure Database:
az postgres flexible-server show --resource-group $RESOURCE_GROUP --name $SERVER_NAME

# Test connection from AKS node
kubectl run -it --rm debug --image=postgres:16 --restart=Never -- psql postgresql://user:pass@fqdn:5432/db
```

### Issue: NGINX Can't Reach Service

```powershell
# Verify service exists
kubectl get svc langflow-api-prod-service -n prod

# Check endpoints
kubectl get endpoints langflow-api-prod-service -n prod

# Test from NGINX pod (if in same cluster)
kubectl exec -it <nginx-pod> -n prod -- curl http://langflow-api-prod-service.prod.svc.cluster.local:80/health
```

---

## 📊 Quick Reference Commands

```powershell
# View all resources
kubectl get all -n prod

# Scale deployment
kubectl scale deployment langflow-api-prod --replicas=3 -n prod

# Restart deployment
kubectl rollout restart deployment/langflow-api-prod -n prod

# Update image
kubectl set image deployment/langflow-api-prod langflow=cera123/langflow:latest -n prod

# View logs
kubectl logs -f deployment/langflow-api-prod -n prod

# Delete everything
kubectl delete namespace prod
```

---

## ✅ Deployment Checklist

- [ ] Resource group created
- [ ] PostgreSQL deployed (ACI or Managed)
- [ ] PostgreSQL FQDN saved
- [ ] pgvector extension enabled
- [ ] AKS cluster created
- [ ] kubectl configured
- [ ] Namespace created
- [ ] Secret key generated
- [ ] Deployment files updated
- [ ] Langflow deployed
- [ ] Pods running
- [ ] Service created
- [ ] NGINX configured
- [ ] Connection tested
- [ ] Application accessible

---

**You're all set! Your Langflow is now running in AKS with Azure PostgreSQL!** 🎉


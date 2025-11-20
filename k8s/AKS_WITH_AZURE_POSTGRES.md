# 🚀 Deploy Langflow in AKS with Azure PostgreSQL

## 📋 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Cloud                              │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Azure Kubernetes Service (AKS)                      │  │
│  │  ┌────────────────────────────────────────────────┐  │  │
│  │  │ Langflow Deployment                             │  │  │
│  │  │ - Image: cera123/langflow:latest               │  │  │
│  │  │ - Service: ClusterIP (langflow-api-prod-service)│  │  │
│  │  │ - Port: 80 → 7860                              │  │  │
│  │  └────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │                                  │
│                          │ External Connection              │
│                          │ (via FQDN or Private Endpoint)   │
│                          ▼                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Option 1: Azure Container Instances (PostgreSQL)   │  │
│  │  - Image: pgvector/pgvector:pg16                    │  │
│  │  - FQDN: langflow-postgres-xxx.region.azurecontainer.io│
│  └──────────────────────────────────────────────────────┘  │
│                          OR                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Option 2: Azure Database for PostgreSQL            │  │
│  │  - Managed Service                                   │  │
│  │  - FQDN: langflow-postgres.postgres.database.azure.com│
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  NGINX (External)                                    │  │
│  │  - Proxies to: langflow-api-prod-service.prod.svc...│  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 🎯 Prerequisites

```powershell
# Install Azure CLI
# Download from: https://aka.ms/installazurecliwindows

# Install kubectl
# Already included with Azure CLI, or download separately

# Login to Azure
az login

# Verify installations
az --version
kubectl version --client
```

---

## 📦 Option 1: PostgreSQL in Azure Container Instances

### Step 1: Create Resource Group

```powershell
$RESOURCE_GROUP = "langflow-aks-rg"
$LOCATION = "eastus"  # Change to your preferred location

az group create --name $RESOURCE_GROUP --location $LOCATION
```

### Step 2: Create PostgreSQL in Azure Container Instances

```powershell
# Set PostgreSQL credentials
$POSTGRES_USER = "langflow"
$POSTGRES_PASSWORD = "YourStrongPassword123!"  # CHANGE THIS!
$POSTGRES_DB = "langflow"

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
    POSTGRES_DB=$POSTGRES_DB `
    POSTGRES_INITDB_ARGS="--encoding=UTF-8" `
  --dns-name-label langflow-postgres-$(Get-Random) `
  --restart-policy Always `
  --ip-address Public

# Get PostgreSQL FQDN
$POSTGRES_FQDN = (az container show --resource-group $RESOURCE_GROUP --name langflow-postgres --query "ipAddress.fqdn" -o tsv)
Write-Host "PostgreSQL FQDN: $POSTGRES_FQDN" -ForegroundColor Green
```

### Step 3: Enable pgvector Extension

```powershell
# Wait for PostgreSQL to be ready (30 seconds)
Start-Sleep -Seconds 30

# Connect and enable pgvector
# You'll need psql installed or use Azure Cloud Shell
# psql postgresql://$POSTGRES_USER`:$POSTGRES_PASSWORD@$POSTGRES_FQDN:5432/$POSTGRES_DB -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

**Alternative: Use init script via volume mount (requires Azure File Share)**

### Step 4: Create AKS Cluster

```powershell
$AKS_NAME = "langflow-aks"
$AKS_NODE_COUNT = 2
$AKS_NODE_SIZE = "Standard_B2s"  # 2 vCPU, 4GB RAM

# Create AKS cluster (takes 10-15 minutes)
az aks create `
  --resource-group $RESOURCE_GROUP `
  --name $AKS_NAME `
  --node-count $AKS_NODE_COUNT `
  --node-vm-size $AKS_NODE_SIZE `
  --enable-addons monitoring `
  --generate-ssh-keys

# Get AKS credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME

# Verify connection
kubectl get nodes
```

### Step 5: Create Namespace

```powershell
kubectl create namespace prod
```

### Step 6: Update Langflow Deployment Files

The deployment files are already created. You just need to update the connection string.

**Update `k8s/langflow-secret.yaml`:**

```yaml
stringData:
  LANGFLOW_DATABASE_URL: "postgresql://langflow:YourStrongPassword123!@langflow-postgres-xxx.eastus.azurecontainer.io:5432/langflow"
```

Replace:
- `YourStrongPassword123!` with your actual PostgreSQL password
- `langflow-postgres-xxx.eastus.azurecontainer.io` with your actual FQDN

### Step 7: Deploy Langflow to AKS

```powershell
# Navigate to k8s directory
cd k8s

# Generate secret key for Langflow
$SECRET_KEY = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})

# Update langflow-secret.yaml with:
# 1. PostgreSQL connection string (from Step 6)
# 2. Generated secret key
# 3. Admin password

# Deploy Langflow
kubectl apply -f langflow-deployment.yaml

# Check deployment status
kubectl get pods -n prod
kubectl get svc -n prod
```

### Step 8: Get ClusterIP Service Details

```powershell
# Get service details
kubectl get svc langflow-api-prod-service -n prod

# Get full service details including ClusterIP
kubectl get svc langflow-api-prod-service -n prod -o yaml

# Get ClusterIP address
$CLUSTER_IP = (kubectl get svc langflow-api-prod-service -n prod -o jsonpath='{.spec.clusterIP}')
$SERVICE_NAME = "langflow-api-prod-service.prod.svc.cluster.local"
$SERVICE_PORT = 80

Write-Host "ClusterIP: $CLUSTER_IP" -ForegroundColor Green
Write-Host "Service Name: $SERVICE_NAME" -ForegroundColor Green
Write-Host "Port: $SERVICE_PORT" -ForegroundColor Green
```

---

## 🗄️ Option 2: Azure Database for PostgreSQL (Recommended for Production)

### Step 1: Create Azure Database for PostgreSQL

```powershell
$RESOURCE_GROUP = "langflow-aks-rg"
$LOCATION = "eastus"
$SERVER_NAME = "langflow-postgres-$(Get-Random)"
$ADMIN_USER = "langflowadmin"
$ADMIN_PASSWORD = "YourStrongPassword123!"  # CHANGE THIS!
$DB_NAME = "langflow"

# Create PostgreSQL Flexible Server
az postgres flexible-server create `
  --resource-group $RESOURCE_GROUP `
  --name $SERVER_NAME `
  --location $LOCATION `
  --admin-user $ADMIN_USER `
  --admin-password $ADMIN_PASSWORD `
  --sku-name Standard_B1ms `
  --tier Burstable `
  --version 16 `
  --storage-size 32 `
  --public-access 0.0.0.0  # Allow all IPs (restrict in production!)

# Create database
az postgres flexible-server db create `
  --resource-group $RESOURCE_GROUP `
  --server-name $SERVER_NAME `
  --database-name $DB_NAME

# Get server FQDN
$POSTGRES_FQDN = (az postgres flexible-server show --resource-group $RESOURCE_GROUP --name $SERVER_NAME --query "fullyQualifiedDomainName" -o tsv)
Write-Host "PostgreSQL FQDN: $POSTGRES_FQDN" -ForegroundColor Green

# Enable pgvector extension
az postgres flexible-server parameter set `
  --resource-group $RESOURCE_GROUP `
  --server-name $SERVER_NAME `
  --name shared_preload_libraries `
  --value "vector"

# Note: You need to restart the server for pgvector to take effect
az postgres flexible-server restart `
  --resource-group $RESOURCE_GROUP `
  --name $SERVER_NAME
```

### Step 2: Connect and Enable pgvector Extension

```powershell
# Install PostgreSQL client (if not installed)
# Or use Azure Cloud Shell which has psql

# Connect to database
$CONNECTION_STRING = "postgresql://${ADMIN_USER}:${ADMIN_PASSWORD}@${POSTGRES_FQDN}:5432/${DB_NAME}"

# Enable pgvector extension
# Run this in psql or Azure Cloud Shell:
# psql $CONNECTION_STRING -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

### Step 3: Configure Firewall Rules

```powershell
# Allow AKS nodes to access PostgreSQL
# Get AKS outbound IPs
$AKS_OUTBOUND_IPS = (az aks show --resource-group $RESOURCE_GROUP --name $AKS_NAME --query "networkProfile.loadBalancerProfile.effectiveOutboundIPs[0].id" -o tsv)

# Or allow specific IP ranges
az postgres flexible-server firewall-rule create `
  --resource-group $RESOURCE_GROUP `
  --name $SERVER_NAME `
  --rule-name AllowAKS `
  --start-ip-address 0.0.0.0 `
  --end-ip-address 255.255.255.255  # Restrict this in production!
```

### Step 4: Update Langflow Connection String

**Update `k8s/langflow-secret.yaml`:**

```yaml
stringData:
  LANGFLOW_DATABASE_URL: "postgresql://langflowadmin:YourStrongPassword123!@langflow-postgres-xxx.postgres.database.azure.com:5432/langflow"
```

### Step 5: Deploy Langflow (Same as Option 1, Step 7)

---

## 🔧 Configure NGINX to Proxy to ClusterIP Service

### Option A: NGINX in Same AKS Cluster

```yaml
# nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: prod
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-config
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: prod
spec:
  type: LoadBalancer  # Or ClusterIP if using Ingress
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: nginx
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: prod
data:
  default.conf: |
    upstream langflow_backend {
        server langflow-api-prod-service.prod.svc.cluster.local:80;
    }
    
    server {
        listen 80;
        server_name _;
        
        client_max_body_size 50M;
        
        location / {
            proxy_pass http://langflow_backend;
            proxy_http_version 1.1;
            
            # WebSocket support
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            
            # Headers
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
            
            # Timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
            
            # Buffering
            proxy_buffering off;
            proxy_request_buffering off;
        }
    }
```

**Deploy NGINX:**
```powershell
kubectl apply -f nginx-deployment.yaml

# Get LoadBalancer IP
kubectl get svc nginx-service -n prod
```

### Option B: NGINX External (VM or Another Service)

**nginx.conf:**
```nginx
upstream langflow_backend {
    # Option 1: Use ClusterIP (requires VPN or peering)
    # server <CLUSTER_IP>:80;
    
    # Option 2: Use LoadBalancer service (recommended)
    # Get LoadBalancer IP from: kubectl get svc langflow-api-prod-service -n prod
    server <LOADBALANCER_IP>:80;
    
    # Option 3: Use service FQDN (if NGINX is in same cluster)
    # server langflow-api-prod-service.prod.svc.cluster.local:80;
}

server {
    listen 80;
    server_name your-domain.com;  # Change this
    
    client_max_body_size 50M;
    
    location / {
        proxy_pass http://langflow_backend;
        proxy_http_version 1.1;
        
        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffering
        proxy_buffering off;
        proxy_request_buffering off;
    }
}
```

**To use ClusterIP from external NGINX:**
1. Expose Langflow service as LoadBalancer (temporary)
2. Or use Ingress Controller
3. Or set up VPN/peering between NGINX and AKS

---

## 📝 Complete Deployment Steps Summary

### Quick Commands

```powershell
# 1. Set variables
$RESOURCE_GROUP = "langflow-aks-rg"
$LOCATION = "eastus"
$AKS_NAME = "langflow-aks"
$POSTGRES_PASSWORD = "YourStrongPassword123!"

# 2. Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# 3. Create PostgreSQL (choose one):
# Option A: Container Instance
az container create --resource-group $RESOURCE_GROUP --name langflow-postgres --image pgvector/pgvector:pg16 --cpu 2 --memory 4 --ports 5432 --environment-variables POSTGRES_USER=langflow POSTGRES_PASSWORD=$POSTGRES_PASSWORD POSTGRES_DB=langflow --dns-name-label langflow-postgres-$(Get-Random) --restart-policy Always

# Option B: Azure Database for PostgreSQL
az postgres flexible-server create --resource-group $RESOURCE_GROUP --name langflow-postgres-$(Get-Random) --location $LOCATION --admin-user langflowadmin --admin-password $POSTGRES_PASSWORD --sku-name Standard_B1ms --tier Burstable --version 16

# 4. Get PostgreSQL FQDN
$POSTGRES_FQDN = # (from previous step output)

# 5. Create AKS cluster
az aks create --resource-group $RESOURCE_GROUP --name $AKS_NAME --node-count 2 --node-vm-size Standard_B2s --enable-addons monitoring --generate-ssh-keys

# 6. Get AKS credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME

# 7. Create namespace
kubectl create namespace prod

# 8. Update langflow-secret.yaml with PostgreSQL connection string

# 9. Deploy Langflow
kubectl apply -f k8s/langflow-deployment.yaml

# 10. Check status
kubectl get pods -n prod
kubectl get svc -n prod

# 11. Get service details for NGINX
kubectl get svc langflow-api-prod-service -n prod -o yaml
```

---

## 🔍 Verification

### Check Langflow Pods

```powershell
kubectl get pods -n prod
kubectl describe pod -l app=langflow-api-prod -n prod
kubectl logs -f deployment/langflow-api-prod -n prod
```

### Test Database Connection

```powershell
# Get Langflow pod name
$POD_NAME = (kubectl get pod -n prod -l app=langflow-api-prod -o jsonpath='{.items[0].metadata.name}')

# Test connection from pod
kubectl exec -it $POD_NAME -n prod -- bash
# Inside pod:
# python -c "import psycopg2; psycopg2.connect('postgresql://user:pass@host:5432/db')"
```

### Test Service

```powershell
# Port forward for testing
kubectl port-forward svc/langflow-api-prod-service -n prod 7860:80

# Test in browser: http://localhost:7860
```

---

## 🛠️ Troubleshooting

### Pods Not Starting

```powershell
# Check pod events
kubectl describe pod -l app=langflow-api-prod -n prod

# Check logs
kubectl logs -f deployment/langflow-api-prod -n prod

# Check if PostgreSQL is accessible
kubectl exec -it <langflow-pod> -n prod -- nc -zv <postgres-fqdn> 5432
```

### Database Connection Issues

1. **Verify PostgreSQL is running:**
```powershell
# For Container Instance
az container show --resource-group $RESOURCE_GROUP --name langflow-postgres

# For Azure Database
az postgres flexible-server show --resource-group $RESOURCE_GROUP --name $SERVER_NAME
```

2. **Check firewall rules:**
```powershell
# For Azure Database
az postgres flexible-server firewall-rule list --resource-group $RESOURCE_GROUP --name $SERVER_NAME
```

3. **Test connection from AKS node:**
```powershell
# Get node IP and test
kubectl run -it --rm debug --image=postgres:16 --restart=Never -- psql postgresql://user:pass@fqdn:5432/db
```

### NGINX Can't Reach Service

1. **Check service exists:**
```powershell
kubectl get svc langflow-api-prod-service -n prod
```

2. **Use LoadBalancer instead of ClusterIP:**
```powershell
kubectl patch svc langflow-api-prod-service -n prod -p '{"spec":{"type":"LoadBalancer"}}'
```

3. **Check service endpoints:**
```powershell
kubectl get endpoints langflow-api-prod-service -n prod
```

---

## 📊 Cost Estimation

### AKS Cluster
- 2 nodes × Standard_B2s: ~$73/month
- Load Balancer: ~$18/month
- **Total: ~$91/month**

### PostgreSQL
- Container Instance: ~$50-80/month (2 CPU, 4GB)
- OR Azure Database: ~$30-100/month (depends on tier)

### Total
- **Option 1 (ACI): ~$141-171/month**
- **Option 2 (Managed DB): ~$121-191/month**

---

## ✅ Next Steps

1. ✅ Deploy PostgreSQL (choose option)
2. ✅ Create AKS cluster
3. ✅ Deploy Langflow
4. ✅ Configure NGINX
5. ✅ Set up monitoring
6. ✅ Configure backups
7. ✅ Set up SSL/TLS
8. ✅ Configure custom domain

---

**Ready to deploy? Follow the steps above!** 🚀


# 🚀 Langflow AKS Deployment - Quick Reference

## 📁 Files Overview

### Deployment Files
- **`langflow-deployment-aks.yaml`** - Complete Langflow deployment for AKS
  - ConfigMap with Langflow settings
  - Secret with database connection and credentials
  - PersistentVolumeClaims for data and logs
  - Deployment with 2 replicas
  - ClusterIP Service (port 80 → 7860)

### NGINX Files
- **`nginx-deployment.yaml`** - NGINX deployment for AKS cluster
- **`nginx-config-example.conf`** - NGINX configuration examples

### Documentation
- **`AKS_WITH_AZURE_POSTGRES.md`** - Complete deployment guide
- **`DEPLOYMENT_STEPS.md`** - Step-by-step instructions
- **`DATABASE_COORDINATION.md`** - How database coordination works

---

## 🎯 Quick Start

### 1. Deploy PostgreSQL (Choose One)

**Option A: Azure Container Instances**
```powershell
az container create --resource-group langflow-aks-rg --name langflow-postgres --image pgvector/pgvector:pg16 --cpu 2 --memory 4 --ports 5432 --environment-variables POSTGRES_USER=langflow POSTGRES_PASSWORD=YourPassword POSTGRES_DB=langflow --dns-name-label langflow-postgres-$(Get-Random) --restart-policy Always
```

**Option B: Azure Database for PostgreSQL**
```powershell
az postgres flexible-server create --resource-group langflow-aks-rg --name langflow-postgres-$(Get-Random) --location eastus --admin-user langflowadmin --admin-password YourPassword --sku-name Standard_B1ms --tier Burstable --version 16
```

### 2. Create AKS Cluster
```powershell
az aks create --resource-group langflow-aks-rg --name langflow-aks --node-count 2 --node-vm-size Standard_B2s --enable-addons monitoring --generate-ssh-keys
az aks get-credentials --resource-group langflow-aks-rg --name langflow-aks
kubectl create namespace prod
```

### 3. Update and Deploy Langflow
```powershell
# Edit langflow-deployment-aks.yaml:
# - Update LANGFLOW_DATABASE_URL with your PostgreSQL FQDN
# - Update passwords
# - Update LANGFLOW_SECRET_KEY

kubectl apply -f langflow-deployment-aks.yaml
kubectl get pods -n prod
```

### 4. Get Service Details for NGINX
```powershell
kubectl get svc langflow-api-prod-service -n prod
# Use: langflow-api-prod-service.prod.svc.cluster.local:80
```

### 5. Deploy NGINX (Optional)
```powershell
kubectl apply -f nginx-deployment.yaml
kubectl get svc nginx-service -n prod
```

---

## 🔑 Key Configuration Points

### Langflow Service (ClusterIP)
- **Service Name**: `langflow-api-prod-service.prod.svc.cluster.local`
- **Port**: 80 (maps to container port 7860)
- **Type**: ClusterIP (internal only)
- **Use in NGINX**: `server langflow-api-prod-service.prod.svc.cluster.local:80;`

### Database Connection String Format

**For Azure Container Instances:**
```
postgresql://langflow:Password@langflow-postgres-xxx.eastus.azurecontainer.io:5432/langflow
```

**For Azure Database for PostgreSQL:**
```
postgresql://langflowadmin:Password@langflow-postgres-xxx.postgres.database.azure.com:5432/langflow
```

---

## 📊 Architecture

```
┌─────────────────────────────────────────┐
│  Azure Kubernetes Service (AKS)         │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ Langflow Deployment (2 replicas)  │ │
│  │ - Image: cera123/langflow:latest │ │
│  │ - Port: 7860                     │ │
│  └───────────────────────────────────┘ │
│              │                          │
│              ▼                          │
│  ┌───────────────────────────────────┐ │
│  │ Service: ClusterIP               │ │
│  │ - Name: langflow-api-prod-service│ │
│  │ - Port: 80 → 7860               │ │
│  └───────────────────────────────────┘ │
│              │                          │
│              ▼                          │
│  ┌───────────────────────────────────┐ │
│  │ NGINX (Optional)                  │ │
│  │ - Proxies to ClusterIP service   │ │
│  │ - LoadBalancer for external access│ │
│  └───────────────────────────────────┘ │
└─────────────────────────────────────────┘
              │
              │ External Connection
              ▼
┌─────────────────────────────────────────┐
│  PostgreSQL (Azure Service)            │
│  - Container Instance OR               │
│  - Azure Database for PostgreSQL      │
└─────────────────────────────────────────┘
```

---

## 🔧 Common Commands

```powershell
# Check deployment status
kubectl get pods -n prod
kubectl get svc -n prod
kubectl get pvc -n prod

# View logs
kubectl logs -f deployment/langflow-api-prod -n prod

# Scale deployment
kubectl scale deployment langflow-api-prod --replicas=3 -n prod

# Restart deployment
kubectl rollout restart deployment/langflow-api-prod -n prod

# Update image
kubectl set image deployment/langflow-api-prod langflow=cera123/langflow:latest -n prod

# Port forward for testing
kubectl port-forward svc/langflow-api-prod-service -n prod 7860:80

# Get service details
kubectl get svc langflow-api-prod-service -n prod -o yaml
```

---

## 📝 NGINX Configuration

### For NGINX in Same AKS Cluster

```nginx
upstream langflow_backend {
    server langflow-api-prod-service.prod.svc.cluster.local:80;
}

server {
    listen 80;
    location / {
        proxy_pass http://langflow_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### For External NGINX

First, expose Langflow as LoadBalancer:
```powershell
kubectl patch svc langflow-api-prod-service -n prod -p '{"spec":{"type":"LoadBalancer"}}'
kubectl get svc langflow-api-prod-service -n prod
```

Then use LoadBalancer IP in NGINX:
```nginx
upstream langflow_backend {
    server <LOADBALANCER_IP>:80;
}
```

---

## ✅ Verification Checklist

- [ ] PostgreSQL is running and accessible
- [ ] AKS cluster is created and connected
- [ ] Langflow pods are running (2/2 ready)
- [ ] Service is created (ClusterIP assigned)
- [ ] Database connection is working
- [ ] Health endpoint responds: `/health`
- [ ] NGINX can reach Langflow service
- [ ] Application is accessible

---

## 🆘 Troubleshooting

### Pods Not Starting
```powershell
kubectl describe pod -l app=langflow-api-prod -n prod
kubectl logs -f deployment/langflow-api-prod -n prod
```

### Database Connection Failed
```powershell
# Test from pod
kubectl exec -it <pod-name> -n prod -- bash
# Inside: python -c "import psycopg2; psycopg2.connect('$LANGFLOW_DATABASE_URL')"
```

### NGINX Can't Reach Service
```powershell
# Verify service exists
kubectl get svc langflow-api-prod-service -n prod

# Test from NGINX pod
kubectl exec -it <nginx-pod> -n prod -- curl http://langflow-api-prod-service.prod.svc.cluster.local:80/health
```

---

## 📚 Full Documentation

- **Complete Guide**: `AKS_WITH_AZURE_POSTGRES.md`
- **Step-by-Step**: `DEPLOYMENT_STEPS.md`
- **Database Details**: `DATABASE_COORDINATION.md`

---

**Ready to deploy? Start with `DEPLOYMENT_STEPS.md`!** 🚀


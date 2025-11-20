# 🚀 AKS Deployment Guide - Pre-built Images

## 📁 Files Created

✅ **k8s/postgres-deployment.yaml** - PostgreSQL database deployment  
✅ **k8s/langflow-deployment.yaml** - Langflow API deployment  
✅ **bitbucket-pipelines.yml** - CI/CD pipeline for AKS  

## ⚠️ BEFORE DEPLOYING - Update Passwords!

### 1. Update PostgreSQL Password

**File**: `k8s/postgres-deployment.yaml`

Find and change:
```yaml
stringData:
  POSTGRES_PASSWORD: "ChangeMeToStrongPassword123!"  # CHANGE THIS!
```

### 2. Update Langflow Passwords

**File**: `k8s/langflow-deployment.yaml`

Find and change:
```yaml
stringData:
  LANGFLOW_SUPERUSER_PASSWORD: "ChangeThisPassword123!"  # CHANGE THIS!
  LANGFLOW_SECRET_KEY: "CHANGE_THIS_TO_RANDOM_SECRET_KEY"  # CHANGE THIS!
  
  # Also update the password in the database URL to match PostgreSQL password
  LANGFLOW_DATABASE_URL: "postgresql://langflow:ChangeMeToStrongPassword123!@postgres-service:5432/langflow"
                                              └─────────────────────────┘
                                              Must match PostgreSQL password!
```

**Generate Secret Key:**
```bash
# Linux/Mac/WSL:
openssl rand -hex 32

# Windows PowerShell:
[System.Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
```

## 🔧 Bitbucket Setup

### Configure Repository Variables

Go to: **Bitbucket → Repository Settings → Pipelines → Repository variables**

Add these variables:

| Variable Name | Value | Secured? |
|---------------|-------|----------|
| `AZURE_CLIENT_ID` | Your service principal App ID | No |
| `AZURE_CLIENT_SECRET` | Your service principal password | ✅ Yes |
| `AZURE_TENANT_ID` | Your Azure tenant ID | No |
| `AZURE_RESOURCE_GROUP` | Your AKS resource group name | No |
| `AKS_CLUSTER_NAME` | Your AKS cluster name | No |

### Create Azure Service Principal

```bash
# Login to Azure
az login

# Create service principal
az ad sp create-for-rbac --name "bitbucket-langflow-sp" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group}

# Output will give you:
# - appId → Use as AZURE_CLIENT_ID
# - password → Use as AZURE_CLIENT_SECRET
# - tenant → Use as AZURE_TENANT_ID
```

## 🚀 Deployment Options

### Option 1: Automatic via Bitbucket (Recommended)

```bash
# 1. Update passwords in YAML files
# 2. Commit and push to main branch
git add .
git commit -m "Deploy Langflow to AKS"
git push origin main

# Pipeline will automatically:
# - Connect to AKS
# - Deploy PostgreSQL
# - Deploy Langflow
# - Verify health checks
```

### Option 2: Manual Deployment

```bash
# 1. Connect to AKS
az login
az aks get-credentials --resource-group <your-rg> --name <your-aks>

# 2. Create namespace
kubectl create namespace prod

# 3. Deploy PostgreSQL
kubectl apply -f k8s/postgres-deployment.yaml

# Wait for PostgreSQL
kubectl wait --for=condition=ready pod -l app=postgres -n prod --timeout=300s

# 4. Deploy Langflow
kubectl apply -f k8s/langflow-deployment.yaml

# Wait for Langflow
kubectl rollout status deployment/langflow-api-prod -n prod

# 5. Verify
kubectl get pods -n prod
kubectl get svc -n prod
```

## 🔍 Verify Deployment

```bash
# Check pods
kubectl get pods -n prod

# Expected output:
# NAME                                 READY   STATUS    RESTARTS   AGE
# postgres-xxxxxxxxxx-xxxxx            1/1     Running   0          2m
# langflow-api-prod-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
# langflow-api-prod-xxxxxxxxxx-xxxxx   1/1     Running   0          1m

# Check services
kubectl get svc -n prod

# Expected output:
# NAME                          TYPE        CLUSTER-IP     PORT(S)
# postgres-service              ClusterIP   10.x.x.x       5432/TCP
# langflow-api-prod-service     ClusterIP   10.x.x.x       80/TCP

# Check health
kubectl logs -f deployment/langflow-api-prod -n prod
```

## 🔗 How They Communicate

```
┌─────────────────────────────────────────────────┐
│              AKS Cluster (prod namespace)        │
│                                                  │
│  ┌──────────────────┐      ┌─────────────────┐ │
│  │  Langflow Pod    │      │  PostgreSQL Pod │ │
│  │  cera123/langflow│─────▶│  pgvector:pg16  │ │
│  │  Port: 7860      │      │  Port: 5432     │ │
│  └──────────────────┘      └─────────────────┘ │
│          ▲                          ▲           │
│          │                          │           │
│  ┌───────┴──────────┐      ┌────────┴────────┐ │
│  │ langflow-api-    │      │ postgres-       │ │
│  │ prod-service     │      │ service         │ │
│  │ ClusterIP:80     │      │ ClusterIP:5432  │ │
│  └──────────────────┘      └─────────────────┘ │
│          ▲                                      │
└──────────┼──────────────────────────────────────┘
           │
    Your NGINX Deployment
```

**Langflow connects to PostgreSQL using:**
```
postgresql://langflow:password@postgres-service:5432/langflow
                                └─────────────┘
                            Kubernetes DNS name
```

**NGINX connects to Langflow using:**
```
langflow-api-prod-service.prod.svc.cluster.local:80
```

## 🔄 Update Images

When you push new images to Docker Hub:

### Option 1: Trigger Pipeline
```bash
git push origin main
# Pipeline automatically restarts pods and pulls latest images
```

### Option 2: Manual Restart
```bash
kubectl rollout restart deployment/langflow-api-prod -n prod
kubectl rollout restart deployment/postgres -n prod
```

### Option 3: Use Bitbucket Custom Pipeline
Go to: **Bitbucket → Pipelines → Run Pipeline**  
Select: **Custom: restart-pods**

## 🧪 Test Communication

```bash
# Get Langflow pod
LANGFLOW_POD=$(kubectl get pod -n prod -l app=langflow-api-prod -o jsonpath='{.items[0].metadata.name}')

# Test PostgreSQL connection from Langflow
kubectl exec -it $LANGFLOW_POD -n prod -- bash

# Inside pod, install PostgreSQL client
apt-get update && apt-get install -y postgresql-client

# Test connection
psql postgresql://langflow:password@postgres-service:5432/langflow -c "SELECT version();"

# Test Langflow health
curl http://localhost:7860/health
```

## 📊 Service Endpoints

**Internal (within cluster):**
- PostgreSQL: `postgres-service.prod.svc.cluster.local:5432`
- Langflow API: `langflow-api-prod-service.prod.svc.cluster.local:80`

**For NGINX Configuration:**
```nginx
upstream langflow_backend {
    server langflow-api-prod-service.prod.svc.cluster.local:80;
}
```

## 🛠️ Troubleshooting

### Pods not starting?
```bash
kubectl describe pod -l app=langflow-api-prod -n prod
kubectl logs -f deployment/langflow-api-prod -n prod
```

### PostgreSQL connection issues?
```bash
# Check PostgreSQL is ready
kubectl get pods -n prod -l app=postgres

# Check PostgreSQL logs
kubectl logs -f deployment/postgres -n prod

# Verify password matches in both files
```

### Pipeline fails?
```bash
# Check Bitbucket variables are set correctly
# Verify Azure credentials are valid
# Check AKS cluster is accessible
```

## 📈 Scaling

Since you're using PostgreSQL, you can scale Langflow horizontally:

```bash
# Scale to 3 replicas
kubectl scale deployment langflow-api-prod --replicas=3 -n prod

# Or use auto-scaling
kubectl autoscale deployment langflow-api-prod \
  --cpu-percent=70 --min=2 --max=10 -n prod
```

## 🎯 Next Steps

1. ✅ Update passwords in both YAML files
2. ✅ Configure Bitbucket repository variables
3. ✅ Push to main branch
4. ✅ Watch pipeline deploy
5. ✅ Verify pods are running
6. ✅ Configure your NGINX to point to Langflow service
7. ✅ Test the application

## 📞 Quick Commands

```bash
# View all resources
kubectl get all -n prod

# Watch pods
kubectl get pods -n prod -w

# Follow logs
kubectl logs -f deployment/langflow-api-prod -n prod

# Port forward for testing
kubectl port-forward svc/langflow-api-prod-service -n prod 7860:80

# Delete everything (careful!)
kubectl delete namespace prod
```

---

**Ready to deploy?** Update the passwords and push to Bitbucket! 🚀


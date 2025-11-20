# Langflow Server Setup Guide (Without PostgreSQL)

This guide will walk you through setting up Langflow on your Kubernetes cluster **without PostgreSQL** (using SQLite instead).

## 📋 Prerequisites

Before starting, ensure you have:

- ✅ Kubernetes cluster running (v1.20+)
- ✅ `kubectl` installed and configured
- ✅ Access to your cluster with admin permissions
- ✅ Docker image pushed to registry: `cera123/langflow:latest`
- ✅ Storage provisioner configured (for persistent volumes)

## 🔍 What's Different from Your Original Files

### Original Issues Fixed:

1. ❌ **No persistent storage** → ✅ Added PersistentVolumeClaims
2. ❌ **No health checks** → ✅ Added liveness, readiness, and startup probes
3. ❌ **No environment configuration** → ✅ Added ConfigMap and Secrets
4. ❌ **No resource limits** → ✅ Added resource requests/limits
5. ❌ **No database configuration** → ✅ Configured SQLite with persistent storage
6. ❌ **Single file** → ✅ Separated concerns into multiple files

## 🚀 Step-by-Step Deployment

### Step 1: Verify Your Cluster

```bash
# Check cluster connection
kubectl cluster-info

# Check available nodes
kubectl get nodes

# Check if namespace exists (create if not)
kubectl get namespace prod || kubectl create namespace prod
```

### Step 2: Configure Storage (Important!)

Check if your cluster has a default storage class:

```bash
kubectl get storageclass
```

**If you see a default storage class:**
- You're good to go! Skip to Step 3.

**If you DON'T have a storage class:**
- You need to configure one based on your infrastructure:

<details>
<summary>For Local/Single Node Cluster (like Minikube)</summary>

```bash
# Use hostPath storage (for testing only)
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF
```

Then update `langflow-pvc.yaml` to add:
```yaml
storageClassName: local-storage
```
</details>

<details>
<summary>For Cloud Providers (AWS/GCP/Azure)</summary>

**AWS EKS:**
- Uses `gp2` or `gp3` by default

**GCP GKE:**
- Uses `standard` or `pd-standard` by default

**Azure AKS:**
- Uses `default` or `managed-premium` by default

Check with: `kubectl get storageclass`
</details>

### Step 3: Update Secrets (CRITICAL!)

**Before deploying, you MUST update the secrets:**

1. Open `langflow-secret.yaml`
2. Change these values:

```yaml
# Generate a strong password
LANGFLOW_SUPERUSER_PASSWORD: "YourStrongPasswordHere!"

# Generate a random secret key
LANGFLOW_SECRET_KEY: "run-this-command-to-generate: openssl rand -hex 32"
```

**Generate secret key:**

```bash
# On Linux/Mac/WSL
openssl rand -hex 32

# On Windows PowerShell (if openssl not available)
[System.Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
```

### Step 4: Deploy to Kubernetes

**Option A: Using the Deployment Script (Recommended)**

```powershell
# Windows PowerShell
cd k8s
.\deploy.ps1
```

```bash
# Linux/Mac
cd k8s
chmod +x deploy.sh
./deploy.sh
```

**Option B: Manual Deployment**

```bash
cd k8s

# 1. Apply ConfigMap
kubectl apply -f langflow-configmap.yaml

# 2. Apply Secrets
kubectl apply -f langflow-secret.yaml

# 3. Create Persistent Volumes
kubectl apply -f langflow-pvc.yaml

# 4. Deploy Application
kubectl apply -f langflow-deployment.yaml
```

### Step 5: Verify Deployment

```bash
# Check if pods are running
kubectl get pods -n prod

# Expected output:
# NAME                                 READY   STATUS    RESTARTS   AGE
# langflow-api-prod-xxxxxxxxxx-xxxxx   1/1     Running   0          2m

# Check service
kubectl get svc -n prod

# Check PVCs are bound
kubectl get pvc -n prod
```

**If pod is not running:**

```bash
# Check pod details
kubectl describe pod -l app=langflow-api-prod -n prod

# Check logs
kubectl logs -l app=langflow-api-prod -n prod
```

### Step 6: Access Langflow

**For Testing (Port Forward):**

```bash
kubectl port-forward svc/langflow-api-prod-service -n prod 7860:80
```

Then open: http://localhost:7860

**For Production (Ingress):**

1. Edit `langflow-ingress.yaml`:
   - Change `langflow.yourdomain.com` to your actual domain
   - Configure TLS/SSL if needed

2. Apply ingress:
   ```bash
   kubectl apply -f langflow-ingress.yaml
   ```

3. Point your domain DNS to your ingress controller IP

## 🔧 Server Configuration Steps

### 1. Install Required Tools on Server

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install kubectl (if not installed)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify installation
kubectl version --client
```

### 2. Configure kubectl Access

```bash
# Copy your kubeconfig to the server
# Method 1: If you have existing config
scp ~/.kube/config user@server:~/.kube/config

# Method 2: Set up from scratch (if using managed K8s)
# For example, with AWS EKS:
# aws eks update-kubeconfig --name your-cluster-name --region your-region
```

### 3. Verify Cluster Access

```bash
kubectl cluster-info
kubectl get nodes
kubectl get namespaces
```

### 4. Upload Kubernetes Manifests

```powershell
# From your local machine (PowerShell)
scp -r k8s user@server:~/langflow-deployment/
```

### 5. Deploy on Server

```bash
# SSH to server
ssh user@server

# Navigate to deployment directory
cd ~/langflow-deployment/k8s

# Update secrets first!
nano langflow-secret.yaml
# (Change passwords and secret key)

# Deploy
chmod +x deploy.sh
./deploy.sh
```

## 📊 Monitoring and Maintenance

### Check Application Status

```bash
# Pod status
kubectl get pods -n prod -l app=langflow-api-prod

# Detailed pod info
kubectl describe pod -l app=langflow-api-prod -n prod

# Application logs
kubectl logs -f deployment/langflow-api-prod -n prod

# Last 100 lines
kubectl logs --tail=100 deployment/langflow-api-prod -n prod

# Resource usage
kubectl top pod -l app=langflow-api-prod -n prod
```

### Check Health Endpoint

```bash
# From inside the cluster
kubectl exec -it deployment/langflow-api-prod -n prod -- curl http://localhost:7860/health

# Expected response:
# {"status":"ok"}
```

### Access Pod Shell (for debugging)

```bash
kubectl exec -it deployment/langflow-api-prod -n prod -- /bin/bash

# Inside pod, check:
ls -la /app/langflow/  # SQLite database location
ls -la /app/logs/       # Log files
```

## 🔄 Updates and Rollbacks

### Update to New Image

```bash
# Update image tag
kubectl set image deployment/langflow-api-prod langflow-api-prod-image=cera123/langflow:v1.0.1 -n prod

# Check rollout status
kubectl rollout status deployment/langflow-api-prod -n prod

# Watch pods being updated
kubectl get pods -n prod -w
```

### Rollback if Issues

```bash
# Rollback to previous version
kubectl rollout undo deployment/langflow-api-prod -n prod

# Rollback to specific revision
kubectl rollout history deployment/langflow-api-prod -n prod
kubectl rollout undo deployment/langflow-api-prod --to-revision=2 -n prod
```

## 🗄️ Data Backup and Recovery

### Backup SQLite Database

```bash
# Create a temporary pod with access to the volume
kubectl run backup-pod --rm -i --tty --image=busybox:latest -n prod \
  --overrides='
{
  "spec": {
    "containers": [{
      "name": "backup",
      "image": "busybox:latest",
      "stdin": true,
      "tty": true,
      "volumeMounts": [{
        "name": "data",
        "mountPath": "/data"
      }]
    }],
    "volumes": [{
      "name": "data",
      "persistentVolumeClaim": {
        "claimName": "langflow-data-pvc"
      }
    }]
  }
}' -- sh

# Inside the backup pod:
ls -la /data/
# Exit and copy the database file
```

**Better approach - Create a backup script:**

```bash
# backup.sh
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
kubectl exec deployment/langflow-api-prod -n prod -- tar czf /tmp/backup-${DATE}.tar.gz /app/langflow
kubectl cp prod/$(kubectl get pod -n prod -l app=langflow-api-prod -o jsonpath='{.items[0].metadata.name}'):/tmp/backup-${DATE}.tar.gz ./backup-${DATE}.tar.gz
echo "Backup created: backup-${DATE}.tar.gz"
```

## 🚨 Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl get pods -n prod

# If status is "Pending":
kubectl describe pod -l app=langflow-api-prod -n prod
# Look for events related to PVC binding or node scheduling

# If status is "CrashLoopBackOff":
kubectl logs -l app=langflow-api-prod -n prod --previous
# Check logs from previous crash
```

### PVC Not Binding

```bash
# Check PVC status
kubectl get pvc -n prod

# If status is "Pending":
kubectl describe pvc langflow-data-pvc -n prod

# Common issues:
# 1. No storage class available
# 2. No storage provisioner
# 3. Insufficient storage on nodes
```

### Cannot Access Langflow

```bash
# Check service
kubectl get svc -n prod

# Test service connectivity
kubectl run test-pod --rm -i --tty --image=busybox -n prod -- sh
# Inside test pod:
wget -O- http://langflow-api-prod-service/health
```

### Database Issues

```bash
# Check if database file exists
kubectl exec deployment/langflow-api-prod -n prod -- ls -la /app/langflow/

# Check database permissions
kubectl exec deployment/langflow-api-prod -n prod -- ls -la /app/langflow/*.db

# If permission issues, check pod security context
```

## 🔐 Security Recommendations

1. **Change default passwords** immediately after first login
2. **Use HTTPS** in production (configure TLS in ingress)
3. **Restrict network access** with NetworkPolicies
4. **Regular backups** of the SQLite database
5. **Update secrets** using kubectl secrets, not plain text files
6. **Enable RBAC** for cluster access control
7. **Use private registry** for your Docker images

## 📈 Scaling Considerations

**Current Setup: SQLite (1 Replica Only)**

- SQLite doesn't support concurrent writes from multiple pods
- Current configuration: `replicas: 1`
- For production with high availability, consider PostgreSQL

**To Scale with PostgreSQL:**

1. Deploy PostgreSQL (or use managed service)
2. Update ConfigMap with database URL:
   ```yaml
   LANGFLOW_DATABASE_URL: "postgresql://user:pass@postgres:5432/langflow"
   ```
3. Increase replicas in deployment

## 🆘 Getting Help

### Useful Commands

```bash
# Get all resources in namespace
kubectl get all -n prod

# Check all events
kubectl get events -n prod --sort-by='.lastTimestamp'

# Check resource quotas
kubectl describe resourcequota -n prod

# Check node resources
kubectl describe nodes

# Export current configuration
kubectl get deployment langflow-api-prod -n prod -o yaml > current-deployment.yaml
```

### Log Collection

```bash
# Save logs to file
kubectl logs deployment/langflow-api-prod -n prod > langflow.log

# Follow logs with timestamps
kubectl logs -f --timestamps deployment/langflow-api-prod -n prod
```

## ✅ Final Checklist

Before going to production:

- [ ] Updated `langflow-secret.yaml` with strong passwords
- [ ] Generated and set `LANGFLOW_SECRET_KEY`
- [ ] Configured storage class for PVCs
- [ ] Tested deployment in staging environment
- [ ] Configured ingress with your domain
- [ ] Set up SSL/TLS certificates
- [ ] Implemented backup strategy
- [ ] Documented access credentials securely
- [ ] Set up monitoring/alerting
- [ ] Tested rollback procedure
- [ ] Configured resource limits appropriately
- [ ] Reviewed security settings

## 📚 Additional Resources

- [Langflow Documentation](https://docs.langflow.org)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)


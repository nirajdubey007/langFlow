# Langflow Kubernetes Deployment Guide

This directory contains Kubernetes manifests for deploying Langflow in production without PostgreSQL (using SQLite).

## 📁 Files Overview

1. **langflow-configmap.yaml** - Configuration settings for Langflow
2. **langflow-secret.yaml** - Sensitive data (passwords, API keys)
3. **langflow-pvc.yaml** - Persistent Volume Claims for data storage
4. **langflow-deployment.yaml** - Main deployment and service
5. **langflow-ingress.yaml** - (Optional) External access configuration

## 🚀 Deployment Steps

### Step 1: Create Namespace (if not exists)

```bash
kubectl create namespace prod
```

### Step 2: Update Secrets

**IMPORTANT**: Before deploying, update the following in `langflow-secret.yaml`:

1. Change `LANGFLOW_SUPERUSER_PASSWORD` to a strong password
2. Generate a secret key:
   ```bash
   openssl rand -hex 32
   ```
   Replace `LANGFLOW_SECRET_KEY` with the generated value

3. (Optional) Add any API keys you need (OpenAI, Anthropic, etc.)

### Step 3: Deploy in Order

```bash
# 1. Apply ConfigMap
kubectl apply -f langflow-configmap.yaml

# 2. Apply Secrets
kubectl apply -f langflow-secret.yaml

# 3. Create Persistent Volumes
kubectl apply -f langflow-pvc.yaml

# 4. Deploy Application
kubectl apply -f langflow-deployment.yaml

# 5. (Optional) Setup Ingress for external access
# kubectl apply -f langflow-ingress.yaml
```

### Step 4: Verify Deployment

```bash
# Check pod status
kubectl get pods -n prod

# Check logs
kubectl logs -f deployment/langflow-api-prod -n prod

# Check service
kubectl get svc -n prod

# Check persistent volumes
kubectl get pvc -n prod
```

## 🔍 Troubleshooting

### Check Pod Status
```bash
kubectl describe pod -l app=langflow-api-prod -n prod
```

### View Logs
```bash
kubectl logs -f deployment/langflow-api-prod -n prod
```

### Check Events
```bash
kubectl get events -n prod --sort-by='.lastTimestamp'
```

### Access Pod Shell
```bash
kubectl exec -it deployment/langflow-api-prod -n prod -- /bin/bash
```

## 🌐 Accessing Langflow

### Option 1: Port Forward (for testing)
```bash
kubectl port-forward svc/langflow-api-prod-service -n prod 7860:80
```
Then access at: http://localhost:7860

### Option 2: Ingress (for production)
1. Update `langflow-ingress.yaml` with your domain
2. Configure your DNS to point to your ingress controller
3. Apply the ingress configuration
4. Access at: http://your-domain.com

### Option 3: NodePort (temporary external access)
Edit the service in `langflow-deployment.yaml` and change:
```yaml
spec:
  type: NodePort
```
Then access via: http://node-ip:node-port

## 📊 Monitoring

### Check Health Status
```bash
kubectl exec -it deployment/langflow-api-prod -n prod -- curl http://localhost:7860/health
```

### Watch Resource Usage
```bash
kubectl top pod -l app=langflow-api-prod -n prod
```

## 🔄 Updates and Rollbacks

### Update Image
```bash
# Your CI/CD pipeline should do this automatically
kubectl set image deployment/langflow-api-prod langflow-api-prod-image=cera123/langflow:new-tag -n prod
```

### Check Rollout Status
```bash
kubectl rollout status deployment/langflow-api-prod -n prod
```

### Rollback if Needed
```bash
kubectl rollout undo deployment/langflow-api-prod -n prod
```

## 🗄️ Data Persistence

Data is stored in two persistent volumes:
- **langflow-data-pvc** (10Gi) - SQLite database and application data
- **langflow-logs-pvc** (5Gi) - Application logs

### Backup Data
```bash
# Create a backup pod
kubectl run backup --rm -i --tty --image=busybox -n prod -- sh

# Inside the pod, copy data
# (This is a simplified example - implement proper backup strategy)
```

## 🔐 Security Notes

1. **Secrets**: Never commit `langflow-secret.yaml` with real credentials to version control
2. **RBAC**: Consider implementing Role-Based Access Control
3. **Network Policies**: Implement network policies to restrict traffic
4. **TLS**: Use HTTPS in production (configure in ingress)

## 📝 Configuration Changes

### Update ConfigMap
```bash
# Edit the configmap
kubectl edit configmap langflow-config -n prod

# Restart pods to apply changes
kubectl rollout restart deployment/langflow-api-prod -n prod
```

### Update Secrets
```bash
# Edit secrets
kubectl edit secret langflow-secret -n prod

# Restart pods
kubectl rollout restart deployment/langflow-api-prod -n prod
```

## 🎯 Resource Scaling

### Scale Replicas
```bash
# Scale up
kubectl scale deployment langflow-api-prod --replicas=3 -n prod

# Scale down
kubectl scale deployment langflow-api-prod --replicas=1 -n prod
```

**Note**: Langflow uses SQLite by default, which doesn't support multiple replicas well. For production with multiple replicas, consider:
1. Using PostgreSQL instead
2. Implementing proper session management
3. Using external storage for the database

## 🔧 Advanced Configuration

### Add API Keys
Edit `langflow-secret.yaml` and add:
```yaml
stringData:
  OPENAI_API_KEY: "sk-..."
  ANTHROPIC_API_KEY: "..."
  # Add other API keys as needed
```

### Adjust Resources
Edit resource limits in `langflow-deployment.yaml`:
```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "4Gi"
    cpu: "2000m"
```

### Configure Storage Class
If your cluster has specific storage classes, update `langflow-pvc.yaml`:
```yaml
spec:
  storageClassName: your-storage-class-name
```

## 📞 Support

For issues or questions:
1. Check Langflow documentation: https://docs.langflow.org
2. Review pod logs: `kubectl logs -f deployment/langflow-api-prod -n prod`
3. Check GitHub issues: https://github.com/langflow-ai/langflow/issues


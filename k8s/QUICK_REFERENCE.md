# Langflow Kubernetes Quick Reference

## 🚀 Quick Deployment

```bash
# 1. Update secrets
nano k8s/langflow-secret.yaml

# 2. Deploy everything
cd k8s && ./deploy.sh

# 3. Access Langflow
kubectl port-forward svc/langflow-api-prod-service -n prod 7860:80
```

## 📋 Common Commands

### Deployment

```bash
# Deploy/Update
kubectl apply -f k8s/

# Check status
kubectl get pods -n prod

# View logs
kubectl logs -f deployment/langflow-api-prod -n prod

# Access shell
kubectl exec -it deployment/langflow-api-prod -n prod -- /bin/bash
```

### Monitoring

```bash
# Pod status
kubectl get pods -n prod -l app=langflow-api-prod

# Detailed info
kubectl describe pod -l app=langflow-api-prod -n prod

# Resource usage
kubectl top pod -l app=langflow-api-prod -n prod

# Events
kubectl get events -n prod --sort-by='.lastTimestamp'

# Health check
kubectl exec deployment/langflow-api-prod -n prod -- curl http://localhost:7860/health
```

### Updates

```bash
# Update image
kubectl set image deployment/langflow-api-prod \
    langflow-api-prod-image=cera123/langflow:new-tag -n prod

# Check rollout
kubectl rollout status deployment/langflow-api-prod -n prod

# Rollout history
kubectl rollout history deployment/langflow-api-prod -n prod

# Rollback
kubectl rollout undo deployment/langflow-api-prod -n prod
```

### Configuration

```bash
# Edit ConfigMap
kubectl edit configmap langflow-config -n prod

# Edit Secret
kubectl edit secret langflow-secret -n prod

# Restart deployment
kubectl rollout restart deployment/langflow-api-prod -n prod
```

### Scaling

```bash
# Scale up
kubectl scale deployment langflow-api-prod --replicas=3 -n prod

# Scale down
kubectl scale deployment langflow-api-prod --replicas=1 -n prod

# Auto-scale (HPA)
kubectl autoscale deployment langflow-api-prod --cpu-percent=70 --min=1 --max=5 -n prod
```

## 🔧 Troubleshooting

### Pod Not Starting

```bash
# Check status
kubectl get pods -n prod

# Describe pod
kubectl describe pod <pod-name> -n prod

# Check logs
kubectl logs <pod-name> -n prod

# Previous logs (if crashed)
kubectl logs <pod-name> -n prod --previous
```

### PVC Issues

```bash
# Check PVC status
kubectl get pvc -n prod

# Describe PVC
kubectl describe pvc langflow-data-pvc -n prod

# Check storage class
kubectl get storageclass
```

### Service Not Accessible

```bash
# Check service
kubectl get svc -n prod

# Test from within cluster
kubectl run test --rm -i --tty --image=busybox -n prod -- sh
# Then: wget -O- http://langflow-api-prod-service/health

# Check endpoints
kubectl get endpoints -n prod
```

### Database Issues

```bash
# Access pod
kubectl exec -it deployment/langflow-api-prod -n prod -- /bin/bash

# Check database
ls -la /app/langflow/*.db

# Check permissions
ls -la /app/langflow/
```

## 🗄️ Data Management

### Backup

```bash
# Backup database
kubectl exec deployment/langflow-api-prod -n prod -- \
    tar czf /tmp/backup.tar.gz /app/langflow

# Copy backup locally
kubectl cp prod/<pod-name>:/tmp/backup.tar.gz ./backup-$(date +%Y%m%d).tar.gz
```

### Restore

```bash
# Copy backup to pod
kubectl cp ./backup.tar.gz prod/<pod-name>:/tmp/

# Restore
kubectl exec deployment/langflow-api-prod -n prod -- \
    tar xzf /tmp/backup.tar.gz -C /
```

## 🔐 Security

### Update Passwords

```bash
# Create new secret
kubectl create secret generic langflow-secret \
    --from-literal=LANGFLOW_SUPERUSER_PASSWORD='newpassword' \
    --from-literal=LANGFLOW_SECRET_KEY='newsecret' \
    --dry-run=client -o yaml | kubectl apply -n prod -f -

# Restart pods
kubectl rollout restart deployment/langflow-api-prod -n prod
```

### Add API Keys

```bash
# Edit secret
kubectl edit secret langflow-secret -n prod

# Add new key (base64 encoded)
echo -n 'your-api-key' | base64

# Restart
kubectl rollout restart deployment/langflow-api-prod -n prod
```

## 📊 Resource Management

### View Resource Usage

```bash
# Current usage
kubectl top pod -l app=langflow-api-prod -n prod

# Node usage
kubectl top nodes

# Describe resources
kubectl describe deployment langflow-api-prod -n prod | grep -A 5 Resources
```

### Update Resource Limits

```bash
# Edit deployment
kubectl edit deployment langflow-api-prod -n prod

# Update resources section:
# resources:
#   requests:
#     memory: "1Gi"
#     cpu: "500m"
#   limits:
#     memory: "4Gi"
#     cpu: "2000m"
```

## 🌐 Access Methods

### Port Forward

```bash
# Forward to localhost
kubectl port-forward svc/langflow-api-prod-service -n prod 7860:80

# Forward to specific address
kubectl port-forward --address 0.0.0.0 svc/langflow-api-prod-service -n prod 7860:80
```

### Ingress

```bash
# Apply ingress
kubectl apply -f k8s/langflow-ingress.yaml

# Check ingress
kubectl get ingress -n prod

# Describe ingress
kubectl describe ingress langflow-ingress -n prod
```

### NodePort (Temporary)

```bash
# Edit service
kubectl edit svc langflow-api-prod-service -n prod

# Change type to NodePort
# spec:
#   type: NodePort

# Get node port
kubectl get svc langflow-api-prod-service -n prod
```

## 🔄 CI/CD Integration

### Update from Pipeline

```bash
# Set new image
kubectl set image deployment/langflow-api-prod \
    langflow-api-prod-image=cera123/langflow:${NEW_TAG} -n prod

# Wait for rollout
kubectl rollout status deployment/langflow-api-prod -n prod --timeout=5m

# Verify
kubectl get pods -n prod -l app=langflow-api-prod
```

### Automated Health Check

```bash
# Wait for ready
kubectl wait --for=condition=ready pod -l app=langflow-api-prod -n prod --timeout=300s

# Check health endpoint
POD=$(kubectl get pod -n prod -l app=langflow-api-prod -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n prod $POD -- curl -f http://localhost:7860/health || \
    kubectl rollout undo deployment/langflow-api-prod -n prod
```

## 📝 Useful One-Liners

```bash
# Get pod name
kubectl get pod -n prod -l app=langflow-api-prod -o jsonpath='{.items[0].metadata.name}'

# Get pod IP
kubectl get pod -n prod -l app=langflow-api-prod -o jsonpath='{.items[0].status.podIP}'

# Get all container images
kubectl get pods -n prod -o jsonpath='{.items[*].spec.containers[*].image}'

# Count restarts
kubectl get pods -n prod -l app=langflow-api-prod -o jsonpath='{.items[*].status.containerStatuses[*].restartCount}'

# Get pod age
kubectl get pods -n prod -l app=langflow-api-prod --sort-by=.metadata.creationTimestamp

# Export current config
kubectl get deployment langflow-api-prod -n prod -o yaml > current-deployment.yaml

# Delete and recreate
kubectl delete deployment langflow-api-prod -n prod
kubectl apply -f k8s/langflow-deployment.yaml

# Force delete pod
kubectl delete pod <pod-name> -n prod --grace-period=0 --force
```

## 🎯 Quick Fixes

### Pod Stuck in Pending

```bash
kubectl describe pod <pod-name> -n prod | grep -A 10 Events
# Check for PVC, resource, or scheduling issues
```

### Pod CrashLoopBackOff

```bash
kubectl logs <pod-name> -n prod --previous
# Check previous crash logs
```

### Can't Access Service

```bash
# Test service connectivity
kubectl run test --rm -i --tty --image=curlimages/curl -n prod -- \
    curl http://langflow-api-prod-service/health
```

### Out of Disk Space

```bash
# Check PVC usage
kubectl exec deployment/langflow-api-prod -n prod -- df -h

# Clean logs
kubectl exec deployment/langflow-api-prod -n prod -- \
    find /app/logs -type f -mtime +7 -delete
```

### Permission Denied

```bash
# Check volume permissions
kubectl exec deployment/langflow-api-prod -n prod -- \
    ls -la /app/langflow

# Fix permissions (if running as root)
kubectl exec deployment/langflow-api-prod -n prod -- \
    chown -R 0:0 /app/langflow
```

## 🔗 Useful Links

- **Health Check**: `http://localhost:7860/health`
- **API Docs**: `http://localhost:7860/docs`
- **Admin UI**: `http://localhost:7860`

## 📞 Emergency Commands

```bash
# Quick restart
kubectl rollout restart deployment/langflow-api-prod -n prod

# Force delete all pods
kubectl delete pods -l app=langflow-api-prod -n prod --grace-period=0 --force

# Complete reinstall
kubectl delete -f k8s/
kubectl apply -f k8s/

# Emergency rollback
kubectl rollout undo deployment/langflow-api-prod -n prod

# Get all info for debugging
kubectl get all -n prod -l app=langflow-api-prod -o yaml > debug-info.yaml
```

## 💡 Pro Tips

1. **Always check logs first**: `kubectl logs -f deployment/langflow-api-prod -n prod`
2. **Use describe for events**: `kubectl describe pod <pod-name> -n prod`
3. **Watch in real-time**: Add `-w` flag to most commands
4. **Use labels**: `-l app=langflow-api-prod` for filtering
5. **Copy before editing**: `kubectl get <resource> -o yaml > backup.yaml`


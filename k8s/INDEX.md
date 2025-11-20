# Langflow Kubernetes Deployment - Complete Documentation Index

## 📁 File Structure

```
k8s/
├── langflow-configmap.yaml      # Application configuration
├── langflow-secret.yaml         # Sensitive data (passwords, API keys)
├── langflow-pvc.yaml           # Persistent storage definitions
├── langflow-deployment.yaml    # Main deployment & service
├── langflow-ingress.yaml       # External access configuration
├── deploy.sh                   # Deployment script (Linux/Mac)
├── deploy.ps1                  # Deployment script (Windows)
├── README.md                   # Main documentation
├── SERVER_SETUP_GUIDE.md       # Complete server setup guide
├── CICD_INTEGRATION.md         # CI/CD pipeline integration
├── QUICK_REFERENCE.md          # Command quick reference
└── INDEX.md                    # This file
```

## 📚 Documentation Overview

### 1. [README.md](README.md)
**Purpose**: Main documentation and deployment guide  
**Use when**: First time setup and general reference  
**Key sections**:
- File overview
- Deployment steps
- Verification procedures
- Troubleshooting
- Monitoring

### 2. [SERVER_SETUP_GUIDE.md](SERVER_SETUP_GUIDE.md)
**Purpose**: Complete server configuration walkthrough  
**Use when**: Setting up from scratch on a new server  
**Key sections**:
- Prerequisites check
- Server configuration
- Step-by-step deployment
- Post-deployment verification
- Security recommendations
- Backup strategies

### 3. [CICD_INTEGRATION.md](CICD_INTEGRATION.md)
**Purpose**: Automated deployment pipeline setup  
**Use when**: Integrating with CI/CD systems  
**Key sections**:
- GitHub Actions example
- GitLab CI/CD example
- Azure DevOps example
- Jenkins pipeline example
- Best practices

### 4. [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
**Purpose**: Quick command reference  
**Use when**: Daily operations and troubleshooting  
**Key sections**:
- Common commands
- Troubleshooting one-liners
- Quick fixes
- Emergency procedures

## 🚀 Quick Start Paths

### Path 1: First Time Deployment (Manual)
1. Read [README.md](README.md) - Overview
2. Follow [SERVER_SETUP_GUIDE.md](SERVER_SETUP_GUIDE.md) - Setup
3. Bookmark [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Daily use

### Path 2: CI/CD Integration
1. Read [README.md](README.md) - Overview
2. Follow [CICD_INTEGRATION.md](CICD_INTEGRATION.md) - Pipeline setup
3. Reference [SERVER_SETUP_GUIDE.md](SERVER_SETUP_GUIDE.md) - Troubleshooting

### Path 3: Quick Deployment (Experienced)
1. Update `langflow-secret.yaml`
2. Run `./deploy.sh` or `./deploy.ps1`
3. Use [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for verification

## 🔧 Configuration Files

### langflow-configmap.yaml
**What it contains**:
- Application settings
- Environment configuration
- Feature flags
- Performance tuning

**When to modify**:
- Changing port numbers
- Adjusting worker count
- Modifying log levels
- Enabling/disabling features

**How to update**:
```bash
kubectl edit configmap langflow-config -n prod
kubectl rollout restart deployment/langflow-api-prod -n prod
```

### langflow-secret.yaml
**What it contains**:
- Admin credentials
- Secret keys
- API keys (optional)
- Sensitive configuration

**When to modify**:
- First deployment (REQUIRED)
- Password changes
- Adding API keys
- Rotating secrets

**⚠️ IMPORTANT**: Never commit with real credentials!

**How to update**:
```bash
# Edit values in the file
nano langflow-secret.yaml

# Apply
kubectl apply -f langflow-secret.yaml

# Restart pods
kubectl rollout restart deployment/langflow-api-prod -n prod
```

### langflow-pvc.yaml
**What it contains**:
- Storage requests
- Access modes
- Storage class configuration

**When to modify**:
- Changing storage size
- Using specific storage class
- Adjusting access modes

**How to update**:
```bash
# Note: Cannot modify size of existing PVC in most cases
# You'll need to create new PVC and migrate data
```

### langflow-deployment.yaml
**What it contains**:
- Pod specification
- Container configuration
- Resource limits
- Health checks
- Volume mounts
- Service definition

**When to modify**:
- Adjusting replicas
- Changing resource limits
- Modifying health check parameters
- Updating image version

**How to update**:
```bash
kubectl apply -f langflow-deployment.yaml
# Or use specific commands:
kubectl set image deployment/langflow-api-prod langflow-api-prod-image=new-image -n prod
```

### langflow-ingress.yaml
**What it contains**:
- External access rules
- Domain configuration
- TLS/SSL settings
- Routing rules

**When to modify**:
- Changing domain name
- Enabling HTTPS
- Adjusting routing rules
- Adding annotations

**How to update**:
```bash
kubectl apply -f langflow-ingress.yaml
```

## 🎯 Common Use Cases

### Use Case 1: Fresh Installation
**Documentation**: [SERVER_SETUP_GUIDE.md](SERVER_SETUP_GUIDE.md)  
**Files needed**: All YAML files  
**Time**: 30-60 minutes

**Steps**:
1. Prepare server and cluster
2. Update secrets
3. Run deployment script
4. Verify installation

### Use Case 2: Update to New Version
**Documentation**: [QUICK_REFERENCE.md](QUICK_REFERENCE.md#updates)  
**Files needed**: None (command line)  
**Time**: 5-10 minutes

**Steps**:
```bash
kubectl set image deployment/langflow-api-prod \
    langflow-api-prod-image=cera123/langflow:new-tag -n prod
kubectl rollout status deployment/langflow-api-prod -n prod
```

### Use Case 3: Configuration Change
**Documentation**: [README.md](README.md#configuration-changes)  
**Files needed**: Specific config file  
**Time**: 5 minutes

**Steps**:
1. Edit configmap or secret
2. Apply changes
3. Restart deployment

### Use Case 4: Troubleshooting Issues
**Documentation**: [QUICK_REFERENCE.md](QUICK_REFERENCE.md#troubleshooting)  
**Files needed**: None  
**Time**: Varies

**Common commands**:
```bash
kubectl get pods -n prod
kubectl logs -f deployment/langflow-api-prod -n prod
kubectl describe pod <pod-name> -n prod
```

### Use Case 5: Backup and Recovery
**Documentation**: [SERVER_SETUP_GUIDE.md](SERVER_SETUP_GUIDE.md#data-backup-and-recovery)  
**Files needed**: None  
**Time**: 10-20 minutes

**Steps**:
1. Create backup
2. Store securely
3. Test restore procedure

### Use Case 6: CI/CD Pipeline Setup
**Documentation**: [CICD_INTEGRATION.md](CICD_INTEGRATION.md)  
**Files needed**: Pipeline config  
**Time**: 1-2 hours

**Steps**:
1. Choose CI/CD platform
2. Configure credentials
3. Set up pipeline
4. Test deployment

## 🔍 Troubleshooting Decision Tree

```
Problem?
│
├─ Pod not starting
│  ├─ Status: Pending → Check PVC and node resources
│  ├─ Status: CrashLoopBackOff → Check logs
│  └─ Status: ImagePullBackOff → Verify image exists
│
├─ Cannot access application
│  ├─ Check service → kubectl get svc -n prod
│  ├─ Check endpoints → kubectl get endpoints -n prod
│  └─ Check ingress → kubectl get ingress -n prod
│
├─ Performance issues
│  ├─ Check resources → kubectl top pod -n prod
│  ├─ Check logs → kubectl logs -f deployment/langflow-api-prod -n prod
│  └─ Adjust resource limits → Edit deployment
│
└─ Data issues
   ├─ Check PVC → kubectl get pvc -n prod
   ├─ Check permissions → kubectl exec ... -- ls -la /app/langflow
   └─ Verify backup → Follow backup procedure
```

**See**: [QUICK_REFERENCE.md](QUICK_REFERENCE.md#troubleshooting) for detailed commands

## 📊 Key Differences from Original Configuration

### Original (Your Files):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: langflow-api-prod
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: langflow-api-prod-image
        image: cera123/langflow:latest
        ports:
          - containerPort: 7860
```

### Issues:
❌ No environment variables  
❌ No persistent storage  
❌ No health checks  
❌ No resource limits  
❌ No database configuration

### Improved (New Configuration):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: langflow-api-prod
spec:
  replicas: 1
  strategy:
    type: RollingUpdate
  template:
    spec:
      containers:
      - name: langflow-api-prod-image
        image: cera123/langflow:latest
        envFrom:
          - configMapRef:
              name: langflow-config
          - secretRef:
              name: langflow-secret
        volumeMounts:
          - name: langflow-data
            mountPath: /app/langflow
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /health
            port: 7860
        readinessProbe:
          httpGet:
            path: /health
            port: 7860
        startupProbe:
          httpGet:
            path: /health
            port: 7860
      volumes:
        - name: langflow-data
          persistentVolumeClaim:
            claimName: langflow-data-pvc
```

### Benefits:
✅ Configuration separated into ConfigMap/Secret  
✅ Data persists across restarts  
✅ Automatic health monitoring  
✅ Resource usage controlled  
✅ SQLite database configured with persistent storage  
✅ Rolling updates with zero downtime

## 🔐 Security Checklist

Before going to production:

- [ ] Changed default admin password in `langflow-secret.yaml`
- [ ] Generated unique secret key (use: `openssl rand -hex 32`)
- [ ] Reviewed and removed unnecessary API keys
- [ ] Configured HTTPS/TLS in ingress
- [ ] Set up network policies (optional)
- [ ] Implemented RBAC (optional)
- [ ] Enabled audit logging (optional)
- [ ] Configured backup strategy
- [ ] Tested rollback procedure
- [ ] Documented access credentials securely
- [ ] Set up monitoring/alerting

**See**: [SERVER_SETUP_GUIDE.md](SERVER_SETUP_GUIDE.md#security-recommendations)

## 📈 Scaling Considerations

### Current Setup: SQLite (Single Replica)
- **Replicas**: 1 (cannot scale horizontally)
- **Database**: SQLite (file-based)
- **Storage**: 10Gi data + 5Gi logs
- **Resources**: 512Mi-2Gi RAM, 250m-1000m CPU

### To Scale Up (Multiple Replicas):
You'll need to switch to PostgreSQL because SQLite doesn't support concurrent writes.

**See**: [README.md](README.md#scaling-considerations) for PostgreSQL setup

### Vertical Scaling (More Resources):
Edit `langflow-deployment.yaml` and adjust:
```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "4Gi"
    cpu: "2000m"
```

## 🆘 Getting Help

### 1. Check Documentation
- Start with relevant section above
- Use search (Ctrl+F) in documents
- Check troubleshooting sections

### 2. Review Logs
```bash
kubectl logs -f deployment/langflow-api-prod -n prod
```

### 3. Check Events
```bash
kubectl get events -n prod --sort-by='.lastTimestamp'
```

### 4. Describe Resources
```bash
kubectl describe pod <pod-name> -n prod
```

### 5. Consult Community
- Langflow GitHub: https://github.com/langflow-ai/langflow
- Langflow Docs: https://docs.langflow.org
- Kubernetes Docs: https://kubernetes.io/docs/

## 📝 Quick Commands Summary

```bash
# Deploy
./deploy.sh  # or deploy.ps1 on Windows

# Status
kubectl get all -n prod

# Logs
kubectl logs -f deployment/langflow-api-prod -n prod

# Access
kubectl port-forward svc/langflow-api-prod-service -n prod 7860:80

# Update
kubectl set image deployment/langflow-api-prod langflow-api-prod-image=cera123/langflow:new-tag -n prod

# Rollback
kubectl rollout undo deployment/langflow-api-prod -n prod

# Restart
kubectl rollout restart deployment/langflow-api-prod -n prod
```

## 🎓 Learning Path

### Beginner
1. Read [README.md](README.md) fully
2. Follow [SERVER_SETUP_GUIDE.md](SERVER_SETUP_GUIDE.md) step-by-step
3. Practice basic commands from [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
4. Learn kubectl basics

### Intermediate
1. Understand each YAML file
2. Practice troubleshooting scenarios
3. Set up monitoring
4. Implement backup procedures

### Advanced
1. Set up [CICD_INTEGRATION.md](CICD_INTEGRATION.md)
2. Implement advanced security (RBAC, NetworkPolicies)
3. Optimize resource usage
4. Consider Helm chart conversion

## 📞 Support Contacts

For production issues:
1. Check logs first
2. Review documentation
3. Create GitHub issue: https://github.com/langflow-ai/langflow/issues
4. Join community discussions

## 🔄 Update History

- **Version 1.0** - Initial deployment configuration
- Added comprehensive documentation
- Included CI/CD integration examples
- Created troubleshooting guides

---

## 📄 Document Quick Links

- **Main README**: [README.md](README.md)
- **Server Setup**: [SERVER_SETUP_GUIDE.md](SERVER_SETUP_GUIDE.md)
- **CI/CD Integration**: [CICD_INTEGRATION.md](CICD_INTEGRATION.md)
- **Quick Reference**: [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- **This Index**: [INDEX.md](INDEX.md)

---

**Last Updated**: 2024  
**Kubernetes Version**: 1.20+  
**Langflow Version**: Latest


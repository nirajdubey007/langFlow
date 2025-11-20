# 🚀 START HERE - Langflow Kubernetes Deployment

**Welcome!** This is your starting point for deploying Langflow to Kubernetes without PostgreSQL.

## 📁 What You Have Now

Your original configuration files have been transformed into a complete production-ready deployment system:

```
k8s/
├── 📝 Kubernetes Configuration Files
│   ├── langflow-configmap.yaml     ← App settings
│   ├── langflow-secret.yaml        ← Passwords & secrets (MUST UPDATE!)
│   ├── langflow-pvc.yaml           ← Storage for data
│   ├── langflow-deployment.yaml    ← Main deployment
│   └── langflow-ingress.yaml       ← External access (optional)
│
├── 🔧 Deployment Scripts
│   ├── deploy.sh                   ← Auto-deploy (Linux/Mac)
│   └── deploy.ps1                  ← Auto-deploy (Windows)
│
└── 📚 Documentation
    ├── START_HERE.md               ← This file!
    ├── CHANGES_SUMMARY.md          ← What changed and why
    ├── README.md                   ← Main documentation
    ├── SERVER_SETUP_GUIDE.md       ← Complete setup guide
    ├── CICD_INTEGRATION.md         ← CI/CD pipeline setup
    ├── QUICK_REFERENCE.md          ← Command reference
    └── INDEX.md                    ← Documentation index
```

## ⚡ Quick Start (3 Steps)

### Step 1: Update Secrets (REQUIRED!)

```bash
# Open the secrets file
nano k8s/langflow-secret.yaml
```

**Change these values:**

```yaml
LANGFLOW_SUPERUSER_PASSWORD: "YourStrongPasswordHere!"  # Change this!
LANGFLOW_SECRET_KEY: "run: openssl rand -hex 32"       # Generate and paste
```

**Generate secret key:**
```bash
# Linux/Mac/WSL:
openssl rand -hex 32

# Windows PowerShell (if openssl not available):
[System.Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
```

### Step 2: Deploy

**Option A - Using Script (Easiest):**
```bash
cd k8s
./deploy.sh         # Linux/Mac
# or
./deploy.ps1        # Windows PowerShell
```

**Option B - Manual:**
```bash
cd k8s
kubectl apply -f langflow-configmap.yaml
kubectl apply -f langflow-secret.yaml
kubectl apply -f langflow-pvc.yaml
kubectl apply -f langflow-deployment.yaml
```

### Step 3: Access Langflow

```bash
# Forward port to your local machine
kubectl port-forward svc/langflow-api-prod-service -n prod 7860:80

# Then open in browser:
# http://localhost:7860
```

**Login with:**
- Username: `admin` (or what you set in secrets)
- Password: (what you set in secrets)

## ✅ Pre-Deployment Checklist

- [ ] kubectl installed and configured
- [ ] Connected to your Kubernetes cluster (`kubectl cluster-info`)
- [ ] Namespace 'prod' exists (or will be created)
- [ ] Updated passwords in `langflow-secret.yaml`
- [ ] Generated and set secret key
- [ ] (Optional) Checked storage class availability

## 🔍 What's Different from Your Original Files?

### Your Original Configuration:
```yaml
# Basic deployment - no persistence, no config, no health checks
apiVersion: apps/v1
kind: Deployment
spec:
  containers:
  - image: cera123/langflow:latest
    ports:
      - containerPort: 7860
```

### New Configuration Adds:
✅ **Persistent Storage** - Data survives restarts (10Gi for data)  
✅ **Configuration Management** - Easy to modify settings  
✅ **Secrets Management** - Secure password storage  
✅ **Health Checks** - Auto-restart if unhealthy  
✅ **Resource Limits** - Prevents resource starvation  
✅ **Rolling Updates** - Zero-downtime deployments  
✅ **SQLite Configuration** - Works without PostgreSQL!  

**See**: [CHANGES_SUMMARY.md](CHANGES_SUMMARY.md) for detailed explanation

## 🎯 Choose Your Path

### Path 1: I Want to Deploy Now! (Quick Start)
1. ✅ You're here - good start!
2. 📝 Update secrets (Step 1 above)
3. 🚀 Run deployment script (Step 2 above)
4. 🌐 Access Langflow (Step 3 above)
5. 📖 Bookmark [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for later

**Time**: 10 minutes

### Path 2: I Want to Understand Everything First
1. ✅ You're here
2. 📚 Read [CHANGES_SUMMARY.md](CHANGES_SUMMARY.md) - What changed
3. 📖 Read [README.md](README.md) - Main documentation
4. 🔧 Read [SERVER_SETUP_GUIDE.md](SERVER_SETUP_GUIDE.md) - Complete guide
5. 🚀 Deploy using steps above
6. 📋 Keep [QUICK_REFERENCE.md](QUICK_REFERENCE.md) handy

**Time**: 1 hour

### Path 3: I Need CI/CD Pipeline
1. ✅ You're here
2. 📝 Update secrets
3. 🚀 Deploy manually first (verify it works)
4. 🔄 Read [CICD_INTEGRATION.md](CICD_INTEGRATION.md)
5. ⚙️ Set up your pipeline
6. 📋 Use [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for troubleshooting

**Time**: 2-3 hours

## 🎓 Key Concepts Explained Simply

### What is a ConfigMap?
**Think of it as**: A settings file  
**Contains**: Non-sensitive configuration (like port numbers, log levels)  
**Why separate**: Easy to change without rebuilding the image

### What is a Secret?
**Think of it as**: A secure password manager  
**Contains**: Sensitive data (passwords, API keys)  
**Why separate**: Kubernetes can encrypt it, and it's not in your deployment

### What is a PersistentVolumeClaim (PVC)?
**Think of it as**: Requesting a hard drive  
**Contains**: Your SQLite database and application data  
**Why needed**: Data survives when pods restart

### What are Health Checks?
**Think of it as**: A heartbeat monitor  
**Does**: Checks if your app is healthy  
**Why needed**: Auto-restarts if something goes wrong

### What are Resource Limits?
**Think of it as**: Setting boundaries  
**Does**: Limits how much CPU/RAM a pod can use  
**Why needed**: Prevents one app from crashing the whole server

## 🔧 Server Setup (If Starting from Scratch)

### 1. Prerequisites on Server

```bash
# Check if kubectl is installed
kubectl version --client

# If not installed:
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify cluster connection
kubectl cluster-info
```

### 2. Upload Files to Server

```powershell
# From your local machine (PowerShell)
scp -r k8s user@your-server:~/langflow-deployment/
```

### 3. Deploy on Server

```bash
# SSH to server
ssh user@your-server

# Navigate to directory
cd ~/langflow-deployment/k8s

# Update secrets!
nano langflow-secret.yaml

# Deploy
chmod +x deploy.sh
./deploy.sh
```

**See**: [SERVER_SETUP_GUIDE.md](SERVER_SETUP_GUIDE.md) for detailed instructions

## 📊 Deployment Flow

```
1. Update Secrets ✏️
   └─> langflow-secret.yaml
   
2. Deploy ConfigMap 📝
   └─> kubectl apply -f langflow-configmap.yaml
   
3. Deploy Secrets 🔐
   └─> kubectl apply -f langflow-secret.yaml
   
4. Create Storage 💾
   └─> kubectl apply -f langflow-pvc.yaml
   └─> Waits for PVC to bind
   
5. Deploy Application 🚀
   └─> kubectl apply -f langflow-deployment.yaml
   └─> Creates pods with:
       • Environment from ConfigMap + Secrets
       • Mounted persistent volumes
       • Health checks enabled
       • Resource limits set
   
6. Service Created 🌐
   └─> langflow-api-prod-service
   └─> Accessible within cluster
   
7. (Optional) Ingress 🔓
   └─> kubectl apply -f langflow-ingress.yaml
   └─> External access configured
```

## ✅ Verify Deployment

### Check if Pods are Running
```bash
kubectl get pods -n prod

# Expected output:
# NAME                                 READY   STATUS    RESTARTS   AGE
# langflow-api-prod-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
```

### Check Service
```bash
kubectl get svc -n prod

# Expected output:
# NAME                          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
# langflow-api-prod-service     ClusterIP   10.x.x.x        <none>        80/TCP    2m
```

### Check Persistent Volumes
```bash
kubectl get pvc -n prod

# Expected output:
# NAME                 STATUS   VOLUME            CAPACITY   ACCESS MODES
# langflow-data-pvc    Bound    pvc-xxxxx         10Gi       RWO
# langflow-logs-pvc    Bound    pvc-xxxxx         5Gi        RWO
```

### View Logs
```bash
kubectl logs -f deployment/langflow-api-prod -n prod

# Should see Langflow starting up
```

### Test Health Endpoint
```bash
kubectl exec deployment/langflow-api-prod -n prod -- \
    curl http://localhost:7860/health

# Expected output:
# {"status":"ok"}
```

## 🚨 Troubleshooting Quick Fixes

### Pod Not Starting?
```bash
# Check what's wrong
kubectl describe pod -l app=langflow-api-prod -n prod

# Common issues:
# - PVC not bound → Check storage class
# - ImagePullBackOff → Check image exists
# - CrashLoopBackOff → Check logs
```

### Can't Access Langflow?
```bash
# Check if service exists
kubectl get svc -n prod

# Check if pods are ready
kubectl get pods -n prod

# Try port-forward again
kubectl port-forward svc/langflow-api-prod-service -n prod 7860:80
```

### Forgot Admin Password?
```bash
# Reset password
kubectl edit secret langflow-secret -n prod
# Update LANGFLOW_SUPERUSER_PASSWORD (base64 encoded)

# Restart pods
kubectl rollout restart deployment/langflow-api-prod -n prod
```

**More solutions**: [QUICK_REFERENCE.md](QUICK_REFERENCE.md#troubleshooting)

## 🎯 Common Tasks

### Update Langflow to New Version
```bash
kubectl set image deployment/langflow-api-prod \
    langflow-api-prod-image=cera123/langflow:new-tag -n prod
```

### Change Configuration
```bash
# Edit settings
kubectl edit configmap langflow-config -n prod

# Restart to apply
kubectl rollout restart deployment/langflow-api-prod -n prod
```

### View Logs
```bash
kubectl logs -f deployment/langflow-api-prod -n prod
```

### Restart Application
```bash
kubectl rollout restart deployment/langflow-api-prod -n prod
```

### Rollback Update
```bash
kubectl rollout undo deployment/langflow-api-prod -n prod
```

## 📚 Documentation Guide

| Document | When to Use | Reading Time |
|----------|-------------|--------------|
| [START_HERE.md](START_HERE.md) | First time, overview | 5 min |
| [CHANGES_SUMMARY.md](CHANGES_SUMMARY.md) | Understand what changed | 10 min |
| [README.md](README.md) | Main reference | 15 min |
| [SERVER_SETUP_GUIDE.md](SERVER_SETUP_GUIDE.md) | Complete setup | 30 min |
| [CICD_INTEGRATION.md](CICD_INTEGRATION.md) | Automation setup | 20 min |
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | Daily operations | 5 min |
| [INDEX.md](INDEX.md) | Find specific topics | 2 min |

## 🔐 Security Reminder

### Before Going to Production:

- [ ] Changed admin password from default
- [ ] Generated unique secret key
- [ ] Removed unused API keys from secrets
- [ ] Configured HTTPS/TLS (in ingress)
- [ ] Tested backup and restore
- [ ] Documented credentials securely (NOT in git!)
- [ ] Set up monitoring/alerts
- [ ] Reviewed resource limits

## 💡 Pro Tips

1. **Always check logs first** when something doesn't work
   ```bash
   kubectl logs -f deployment/langflow-api-prod -n prod
   ```

2. **Use describe for debugging** - it shows events and errors
   ```bash
   kubectl describe pod <pod-name> -n prod
   ```

3. **Test in staging first** before deploying to production

4. **Keep backups** of your data (see SERVER_SETUP_GUIDE.md)

5. **Use the deployment scripts** - they check for common issues

6. **Bookmark QUICK_REFERENCE.md** - you'll use it often

## 🆘 Need Help?

### 1. Check Documentation
- Issue with deployment? → [README.md](README.md)
- Setting up server? → [SERVER_SETUP_GUIDE.md](SERVER_SETUP_GUIDE.md)
- Need a command? → [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- CI/CD issues? → [CICD_INTEGRATION.md](CICD_INTEGRATION.md)

### 2. Check Logs
```bash
kubectl logs -f deployment/langflow-api-prod -n prod
```

### 3. Check Events
```bash
kubectl get events -n prod --sort-by='.lastTimestamp'
```

### 4. Community Resources
- Langflow Docs: https://docs.langflow.org
- Langflow GitHub: https://github.com/langflow-ai/langflow
- Kubernetes Docs: https://kubernetes.io/docs/

## ✨ What Makes This Setup Special

1. **Works Without PostgreSQL** ✅
   - Uses SQLite with persistent storage
   - Perfect for most use cases
   - Easy to upgrade to PostgreSQL later if needed

2. **Production-Ready** ✅
   - Health checks
   - Resource limits
   - Rolling updates
   - Data persistence

3. **Well-Documented** ✅
   - 7+ documentation files
   - Examples for everything
   - Troubleshooting guides

4. **Automated** ✅
   - Deployment scripts
   - CI/CD examples
   - One-command deploy

5. **Secure** ✅
   - Kubernetes secrets
   - Encrypted passwords
   - Best practices followed

## 🎉 Ready to Deploy?

**Quick Checklist:**

1. [ ] Read this file (you're doing it!)
2. [ ] Update `langflow-secret.yaml`
3. [ ] Run `./deploy.sh` (or `./deploy.ps1`)
4. [ ] Wait for pods to be ready
5. [ ] Access via port-forward
6. [ ] Login and start using Langflow!

**Time to deploy**: 10 minutes ⏱️

---

## 📞 Quick Command Reference

```bash
# Deploy
./deploy.sh

# Status
kubectl get pods -n prod

# Logs
kubectl logs -f deployment/langflow-api-prod -n prod

# Access
kubectl port-forward svc/langflow-api-prod-service -n prod 7860:80

# Restart
kubectl rollout restart deployment/langflow-api-prod -n prod

# Rollback
kubectl rollout undo deployment/langflow-api-prod -n prod
```

---

**Good luck with your deployment! 🚀**

**Next Steps After Deployment:**
1. ✅ Login to Langflow
2. ✅ Create your first flow
3. ✅ Test everything works
4. ✅ Set up backups
5. ✅ (Optional) Configure CI/CD
6. ✅ (Optional) Set up ingress for external access

**Questions?** Check the other documentation files or create a GitHub issue.

---

**Last Updated**: 2024  
**Kubernetes Version**: 1.20+  
**Langflow Version**: Latest  
**Database**: SQLite (no PostgreSQL required!)


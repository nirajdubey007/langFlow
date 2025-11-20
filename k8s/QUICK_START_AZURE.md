# 🚀 Quick Start: Deploy Langflow to Azure

## ⚡ Fastest Deployment (15 minutes)

### Prerequisites
```powershell
# Install Azure CLI if not installed
# Download from: https://aka.ms/installazurecliwindows

# Login to Azure
az login
```

### Step 1: Set Variables
```powershell
$RESOURCE_GROUP = "langflow-rg"
$LOCATION = "eastus"
$POSTGRES_PASSWORD = "YourStrongPassword123!"
$LANGFLOW_ADMIN_PASSWORD = "AdminPassword123!"
```

### Step 2: Create Resource Group
```powershell
az group create --name $RESOURCE_GROUP --location $LOCATION
```

### Step 3: Deploy PostgreSQL
```powershell
az container create `
  --resource-group $RESOURCE_GROUP `
  --name langflow-postgres `
  --image pgvector/pgvector:pg16 `
  --cpu 1 --memory 2 `
  --ports 5432 `
  --environment-variables `
    POSTGRES_USER=langflow `
    POSTGRES_PASSWORD=$POSTGRES_PASSWORD `
    POSTGRES_DB=langflow `
  --dns-name-label langflow-postgres-$(Get-Random) `
  --restart-policy Always
```

### Step 4: Get PostgreSQL FQDN
```powershell
$POSTGRES_FQDN = (az container show --resource-group $RESOURCE_GROUP --name langflow-postgres --query "ipAddress.fqdn" -o tsv)
Write-Host "PostgreSQL FQDN: $POSTGRES_FQDN"
```

### Step 5: Deploy Langflow
```powershell
az container create `
  --resource-group $RESOURCE_GROUP `
  --name langflow-app `
  --image cera123/langflow:latest `
  --cpu 2 --memory 4 `
  --ports 7860 `
  --environment-variables `
    LANGFLOW_DATABASE_URL="postgresql://langflow:${POSTGRES_PASSWORD}@${POSTGRES_FQDN}:5432/langflow" `
    LANGFLOW_HOST=0.0.0.0 `
    LANGFLOW_PORT=7860 `
    LANGFLOW_SUPERUSER=admin `
    LANGFLOW_SUPERUSER_PASSWORD=$LANGFLOW_ADMIN_PASSWORD `
    LANGFLOW_AUTO_LOGIN=false `
    DO_NOT_TRACK=true `
    LANGFLOW_CONFIG_DIR=/app/langflow `
    LANGFLOW_CORS_ORIGINS=* `
  --dns-name-label langflow-app-$(Get-Random) `
  --restart-policy Always
```

### Step 6: Get Langflow URL
```powershell
$LANGFLOW_FQDN = (az container show --resource-group $RESOURCE_GROUP --name langflow-app --query "ipAddress.fqdn" -o tsv)
Write-Host "`n✅ Langflow is ready!`n"
Write-Host "URL: http://${LANGFLOW_FQDN}:7860" -ForegroundColor Green
Write-Host "Username: admin" -ForegroundColor Yellow
Write-Host "Password: $LANGFLOW_ADMIN_PASSWORD" -ForegroundColor Yellow
```

### Step 7: Check Status
```powershell
# View logs
az container logs --resource-group $RESOURCE_GROUP --name langflow-app --follow

# Check status
az container show --resource-group $RESOURCE_GROUP --name langflow-app --query "containers[0].instanceView.currentState.state"
```

## 🎯 What Happens Behind the Scenes

1. **PostgreSQL Container Starts**
   - Creates database: `langflow`
   - Enables pgvector extension
   - Listens on port 5432
   - Gets public FQDN: `langflow-postgres-xxxxx.eastus.azurecontainer.io`

2. **Langflow Container Starts**
   - Reads connection string with PostgreSQL FQDN
   - Connects to PostgreSQL over internet
   - Creates database schema
   - Starts web server on port 7860
   - Gets public FQDN: `langflow-app-xxxxx.eastus.azurecontainer.io`

3. **Communication**
   - Langflow → PostgreSQL: Via public FQDN
   - User → Langflow: Via public FQDN:7860

## 🔍 Troubleshooting

### Container Not Starting?
```powershell
# Check logs
az container logs --resource-group $RESOURCE_GROUP --name langflow-app

# Check events
az container show --resource-group $RESOURCE_GROUP --name langflow-app --query "containers[0].instanceView.events"
```

### Database Connection Failed?
```powershell
# Verify PostgreSQL is running
az container show --resource-group $RESOURCE_GROUP --name langflow-postgres

# Test connection (from your computer)
# Install psql: https://www.postgresql.org/download/
psql postgresql://langflow:$POSTGRES_PASSWORD@$POSTGRES_FQDN:5432/langflow
```

### Can't Access Langflow?
```powershell
# Check if container is running
az container show --resource-group $RESOURCE_GROUP --name langflow-app --query "containers[0].instanceView.currentState.state"

# Should return: "Running"
```

## 📊 Cost Estimate

- PostgreSQL: ~$30-50/month
- Langflow: ~$50-80/month
- **Total: ~$80-130/month**

## 🔄 Update Your Image

When you push a new image to Docker Hub:

```powershell
# Restart container to pull latest
az container restart --resource-group $RESOURCE_GROUP --name langflow-app
```

## 🗑️ Clean Up

```powershell
# Delete everything
az group delete --name $RESOURCE_GROUP --yes
```

## 📝 Next Steps

1. ✅ Access Langflow at the URL provided
2. ✅ Login with admin credentials
3. ✅ Create your first flow
4. ✅ Configure custom domain (optional)
5. ✅ Set up monitoring (optional)

---

**That's it! Your Langflow is now running on Azure!** 🎉


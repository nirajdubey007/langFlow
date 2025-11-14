# 🚀 Langflow Cloud Deployment Guide

## 📋 Issue Resolution

**Original Problem**: Docker build was failing with "exec format error" due to Windows line endings (CRLF) in the Dockerfile being interpreted as part of shell commands in the Linux container.

**Solution**: Created `build_and_push_fixed.Dockerfile` with proper Unix line endings and fixed multi-line RUN commands.

## 🛠️ Files in This Package

- **`build_and_push_fixed.Dockerfile`** - Fixed Dockerfile with proper line endings
- **`docker-compose.yml`** - Complete Docker Compose configuration
- **`DOCKER_README.md`** - Detailed setup and troubleshooting documentation
- **`build_and_push.ps1`** - Automated build and push script
- **`DEPLOYMENT_GUIDE.md`** - This guide

## 🚀 Deployment Steps

### For You (Developer):

#### Step 1: Build and Push Your Custom Image
```bash
# Navigate to the project root (not deployment folder)
cd /path/to/langflow

# Run the build and push script
.\langflow-deployment\build_and_push.ps1
```

This will:
- Build the Docker image with tag `cera123/langflow:latest`
- Test it locally
- Push it to Docker Hub

#### Step 2: Verify the Push
```bash
# Check if image was pushed successfully
docker pull cera123/langflow:latest
```

### For Cloud Team:

#### Step 1: Update Docker Compose
The cloud team needs to update the `docker-compose.yml` file:

```yaml
# Change this line in docker-compose.yml:
image: langflowai/langflow:latest

# To this:
image: cera123/langflow:latest
```

#### Step 2: Deploy
```bash
# Start the services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f langflow
```

#### Step 3: Access Application
- **URL**: `http://your-server:7860`
- **Default Admin**: `admin` / `admin123` (change in production!)

## 🔧 Environment Configuration

### Production Environment Variables
```bash
# Security (IMPORTANT!)
LANGFLOW_AUTO_LOGIN=false
LANGFLOW_SUPERUSER=your-admin-user
LANGFLOW_SUPERUSER_PASSWORD=your-secure-password

# Database (if using external PostgreSQL)
LANGFLOW_DATABASE_URL=postgresql://user:pass@db-host:5432/langflow

# CORS (configure for your domain)
LANGFLOW_CORS_ORIGINS=https://yourdomain.com

# Disable telemetry
DO_NOT_TRACK=true
```

## 🐛 Troubleshooting

### Build Issues
- **Disk Space**: Ensure 4GB+ free space
- **Line Endings**: Use the `build_and_push_fixed.Dockerfile` (not the original)
- **Platform**: Ensure Docker Desktop is running

### Runtime Issues
- **Port Conflicts**: Check if ports 7860, 5432 are available
- **Database Connection**: Verify PostgreSQL is healthy
- **Permissions**: Ensure proper volume permissions

### Health Checks
```bash
# Check Langflow health
curl http://localhost:7860/health

# Check database connectivity
docker-compose exec postgres pg_isready -U langflow
```

## 🔒 Security Checklist

- [ ] Change default admin password
- [ ] Set `LANGFLOW_AUTO_LOGIN=false`
- [ ] Configure proper CORS origins
- [ ] Use HTTPS in production
- [ ] Set up proper database credentials
- [ ] Enable database backups
- [ ] Configure log rotation
- [ ] Set up monitoring and alerts

## 📞 Support

If issues persist:
1. Check the logs: `docker-compose logs -f`
2. Verify Docker resource allocation (4GB+ RAM, adequate CPU)
3. Test locally first before cloud deployment
4. Ensure cloud server meets system requirements

---

## ✅ Success Indicators

- ✅ `docker-compose ps` shows both containers as "Up"
- ✅ `curl http://localhost:7860/health` returns `{"status":"ok"}`
- ✅ Browser access to `http://your-server:7860` loads Langflow UI
- ✅ Can create and run flows successfully

**🎉 Your Langflow deployment is ready for production!**

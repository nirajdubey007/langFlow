# 🚀 Deploy Langflow on macOS - Complete Guide

This guide will help you deploy your customized Langflow (with Automate branding) using Docker.

## 📋 Prerequisites

1. **Docker Desktop** installed and running
   - Download from: https://www.docker.com/products/docker-desktop
   - Make sure it's running (check the menu bar)

2. **Git** (usually pre-installed on macOS)

3. **Your customizations are ready**
   - Dark theme (#01051f)
   - "Automate" branding
   - "Login" / "Register" text
   - No Langflow logos

## 🎯 Quick Start (3 Steps)

### Step 1: Build Your Custom Docker Image

```bash
cd /Users/niraj/Desktop/langFlowBrained/langFlow/langflow-deployment
./build-and-test.sh
```

This will:
- Build the Docker image with all your customizations
- Test it locally on http://localhost:7860
- Take about 15-30 minutes (first time)

**Verify your customizations:**
- Open http://localhost:7860
- Check that you see:
  - Dark background (#01051f)
  - "Automate" in the title
  - "Login" button text
  - No Langflow logos

### Step 2: Deploy with Docker Compose

```bash
# Make sure the test container is stopped
docker stop langflow-test 2>/dev/null || true

# Deploy with PostgreSQL
./deploy.sh
```

This will:
- Start Langflow with PostgreSQL database
- Create persistent volumes for data
- Set up health checks

### Step 3: Access Your Application

- **URL**: http://localhost:7860
- **Admin Username**: `admin`
- **Admin Password**: `admin123`

## 📦 Option: Push to Docker Hub

If you want to deploy this image to other servers:

```bash
# Set your Docker Hub username (optional, defaults to nirajdubey007)
export DOCKER_USERNAME=your-dockerhub-username

# Login to Docker Hub
docker login

# Push the image
./push-to-hub.sh
```

Then update `docker-compose.yml` to use your image:
```yaml
image: your-dockerhub-username/langflow:latest
```

## 🔧 Configuration

### Environment Variables

Edit `docker-compose.yml` to customize:

```yaml
environment:
  # Change admin credentials (IMPORTANT for production!)
  - LANGFLOW_SUPERUSER=admin
  - LANGFLOW_SUPERUSER_PASSWORD=your-secure-password
  
  # Disable auto-login for production
  - LANGFLOW_AUTO_LOGIN=false
  
  # Database (if using external PostgreSQL)
  - LANGFLOW_DATABASE_URL=postgresql://user:pass@host:5432/langflow
```

### Ports

- **Langflow**: 7860 (change in docker-compose.yml if needed)
- **PostgreSQL**: 5432 (internal only, not exposed by default)

## 🛠️ Useful Commands

### View Logs
```bash
# All services
docker-compose logs -f

# Just Langflow
docker-compose logs -f langflow

# Just PostgreSQL
docker-compose logs -f postgres
```

### Stop Services
```bash
docker-compose down
```

### Restart Services
```bash
docker-compose restart
```

### Check Status
```bash
docker-compose ps
```

### Access Container Shell
```bash
# Langflow container
docker-compose exec langflow sh

# PostgreSQL container
docker-compose exec postgres psql -U langflow -d langflow
```

### Clean Up (Remove Everything)
```bash
# Stop and remove containers, networks, volumes
docker-compose down -v

# Remove images
docker rmi nirajdubey007/langflow:latest
```

## 🐛 Troubleshooting

### "Docker is not running"
- Start Docker Desktop from Applications
- Wait for it to fully start (whale icon in menu bar)

### "Port 7860 is already in use"
```bash
# Find what's using the port
lsof -i :7860

# Stop the process or change port in docker-compose.yml
```

### "Build failed"
- Check you have enough disk space (4GB+ free)
- Ensure Docker Desktop has enough resources (4GB+ RAM)
- Try: `docker system prune -a` to free space

### "Container keeps restarting"
```bash
# Check logs for errors
docker-compose logs langflow

# Check if PostgreSQL is healthy
docker-compose ps postgres
```

### "Can't connect to database"
- Wait 30 seconds for PostgreSQL to initialize
- Check: `docker-compose logs postgres`
- Verify database credentials in docker-compose.yml

### "Customizations not showing"
- Make sure you built the image (not using a pre-built one)
- Clear browser cache (Cmd+Shift+R)
- Check that frontend build included your changes:
  ```bash
  docker run --rm nirajdubey007/langflow:latest ls -la /app/langflow/frontend
  ```

## 📊 Health Checks

### Check Langflow Health
```bash
curl http://localhost:7860/health
```

Should return: `{"status":"ok"}`

### Check PostgreSQL Health
```bash
docker-compose exec postgres pg_isready -U langflow
```

## 🔒 Production Checklist

Before deploying to production:

- [ ] Change default admin password
- [ ] Set `LANGFLOW_AUTO_LOGIN=false`
- [ ] Configure proper CORS origins
- [ ] Use HTTPS (set up reverse proxy)
- [ ] Set up database backups
- [ ] Configure log rotation
- [ ] Set up monitoring
- [ ] Review security settings

## 📚 File Structure

```
langflow-deployment/
├── docker-compose.yml          # Main deployment config
├── build-and-test.sh          # Build and test script
├── push-to-hub.sh             # Push to Docker Hub
├── deploy.sh                  # Deploy with docker-compose
└── DEPLOY_MACOS.md            # This guide
```

## 🎉 Success Indicators

You'll know it's working when:

- ✅ `docker-compose ps` shows both containers as "Up"
- ✅ `curl http://localhost:7860/health` returns `{"status":"ok"}`
- ✅ Browser shows your custom "Automate" branding
- ✅ Dark theme (#01051f) is visible
- ✅ You can create and run flows

## 🆘 Need Help?

1. Check logs: `docker-compose logs -f`
2. Verify Docker resources (Settings → Resources in Docker Desktop)
3. Ensure all prerequisites are met
4. Try rebuilding: `./build-and-test.sh`

---

**Ready to deploy? Start with Step 1!** 🚀


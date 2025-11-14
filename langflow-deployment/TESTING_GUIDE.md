# Langflow Docker Build and Test Guide

This guide will help you build, test, and push your Langflow Docker image to Docker Hub.

## 📋 Prerequisites

1. **Docker Desktop** installed and running on Windows
2. **Docker Hub account** (username: `cera123`)
3. At least **10GB** of free disk space for the build

## 🔍 Dockerfile Analysis

Your Dockerfile (`build_and_push_fixed.Dockerfile`) is **properly configured** for Langflow:

✅ **Multi-stage build** - Optimizes final image size  
✅ **Python 3.12** - Matches project requirements  
✅ **Manual UV installation** - Better multi-platform support  
✅ **Frontend build included** - Builds React app and bundles it  
✅ **PostgreSQL support** - Includes database extras  
✅ **Security hardened** - Runs as non-root user  

## 🚀 Quick Start

### Step 1: Build and Test Locally

Open PowerShell in the project root and run:

```powershell
cd langflow-deployment
.\build-and-test.ps1
```

This script will:
- ✓ Check if Docker is running
- ✓ Build the image with tag `cera123/langflow:test-local`
- ✓ Start a test container on port 7860
- ✓ Show container logs
- ✓ Provide next steps

**Expected build time:** 15-30 minutes (first build)

### Step 2: Test the Application

Once the build completes and container starts:

1. Open your browser to: **http://localhost:7860**
2. You should see the Langflow UI
3. Test basic functionality:
   - Create a new flow
   - Add some components
   - Try running a simple flow

### Step 3: View Logs (Optional)

To see real-time logs:

```powershell
docker logs -f langflow-test
```

Press `Ctrl+C` to stop viewing logs (container keeps running).

### Step 4: Push to Docker Hub

Once you've verified the image works locally:

```powershell
.\push-to-hub.ps1
```

This will:
- ✓ Login to Docker Hub (if needed)
- ✓ Tag the image as `latest` and with version number
- ✓ Push to your repository: `cera123/langflow`

## 🛠️ Manual Commands

If you prefer to run commands manually:

### Build Image

```powershell
cd C:\Users\Niraj\lf\langflow
docker build -f langflow-deployment/build_and_push_fixed.Dockerfile -t cera123/langflow:test-local .
```

### Run Container

```powershell
docker run -d --name langflow-test -p 7860:7860 cera123/langflow:test-local
```

### Check Logs

```powershell
docker logs langflow-test
```

### Stop and Remove Container

```powershell
docker stop langflow-test
docker rm langflow-test
```

### Tag for Docker Hub

```powershell
docker tag cera123/langflow:test-local cera123/langflow:latest
```

### Push to Docker Hub

```powershell
docker login
docker push cera123/langflow:latest
```

## 📦 Image Details

**Expected Image Size:** ~2-3 GB (compressed)

**What's Included:**
- Python 3.12 runtime
- Langflow backend (FastAPI)
- Langflow frontend (React - pre-built)
- All Python dependencies
- PostgreSQL support
- Git (for component management)

**Environment Variables:**
- `LANGFLOW_HOST=0.0.0.0`
- `LANGFLOW_PORT=7860`

## 🔧 Troubleshooting

### Build Fails with "context deadline exceeded"

**Solution:** Enable BuildKit and increase timeout:

```powershell
$env:DOCKER_BUILDKIT=1
docker build --network=host -f langflow-deployment/build_and_push_fixed.Dockerfile -t cera123/langflow:test-local .
```

### Build Fails at Frontend Stage

**Solution:** Clear npm cache:

```powershell
docker build --no-cache -f langflow-deployment/build_and_push_fixed.Dockerfile -t cera123/langflow:test-local .
```

### Container Starts but Can't Access UI

**Solution:** Check if port 7860 is already in use:

```powershell
# Check what's using port 7860
netstat -ano | findstr :7860

# Use a different port
docker run -d --name langflow-test -p 8080:7860 cera123/langflow:test-local
# Then access at http://localhost:8080
```

### Out of Disk Space

**Solution:** Clean up old Docker images:

```powershell
# Remove unused images
docker image prune -a

# See disk usage
docker system df
```

### UV Sync Fails

**Issue:** Platform-specific dependency resolution

**Solution:** The Dockerfile already handles this by installing UV manually. If you still face issues, try building with:

```powershell
docker build --platform=linux/amd64 -f langflow-deployment/build_and_push_fixed.Dockerfile -t cera123/langflow:test-local .
```

## 🧹 Cleanup

To remove test containers and free up space:

```powershell
.\cleanup.ps1
```

Or manually:

```powershell
# Stop and remove container
docker stop langflow-test
docker rm langflow-test

# Remove test image (optional)
docker rmi cera123/langflow:test-local
```

## 📝 Notes

### Multi-Platform Build

Your Dockerfile supports multi-platform builds. To build for both AMD64 and ARM64:

```powershell
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 -f langflow-deployment/build_and_push_fixed.Dockerfile -t cera123/langflow:latest --push .
```

### Using the Image in Production

Once pushed to Docker Hub, anyone can use it:

```bash
# Pull the image
docker pull cera123/langflow:latest

# Run with persistent storage
docker run -d \
  --name langflow \
  -p 7860:7860 \
  -v langflow-data:/app/langflow \
  cera123/langflow:latest

# Run with custom environment
docker run -d \
  --name langflow \
  -p 7860:7860 \
  -e LANGFLOW_DATABASE_URL=postgresql://user:pass@db:5432/langflow \
  -e LANGFLOW_LOG_LEVEL=DEBUG \
  cera123/langflow:latest
```

### Docker Compose

You can also use docker-compose. See `docker-compose.yml` in the same directory.

## ✅ Verification Checklist

Before pushing to Docker Hub, verify:

- [ ] Image builds successfully without errors
- [ ] Container starts and runs
- [ ] Can access UI at http://localhost:7860
- [ ] Can create and run a simple flow
- [ ] Container logs show no critical errors
- [ ] Image size is reasonable (~2-3 GB)

## 🆘 Getting Help

If you encounter issues:

1. Check the logs: `docker logs langflow-test`
2. Check Docker status: `docker info`
3. Review Dockerfile comments
4. Check Langflow documentation: https://docs.langflow.org

## 📚 Additional Resources

- [Langflow Documentation](https://docs.langflow.org)
- [Docker Hub Repository](https://hub.docker.com/r/cera123/langflow)
- [Dockerfile Best Practices](https://docs.docker.com/develop/dev-best-practices/)


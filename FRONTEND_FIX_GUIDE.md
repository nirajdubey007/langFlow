# Frontend Fix Guide - Langflow

## Problem
The Docker image `cera123/langflow:latest` or `langflowai/langflow:latest` is missing the frontend files, resulting in the error:
```
File at path /app/.venv/lib/python3.12/site-packages/langflow/frontend/index.html does not exist.
```

## Solution 1: Build from Source (Recommended)

I've created a custom Dockerfile that builds both frontend and backend. Follow these steps:

### Prerequisites
1. Make sure Docker Desktop is running
2. Ensure you have at least 10GB of free disk space

### Steps

1. **Start Docker Desktop**
   - Open Docker Desktop application
   - Wait for it to fully start

2. **Stop existing containers**
   ```powershell
   docker-compose down -v
   ```

3. **Build the custom image** (This will take 10-15 minutes)
   ```powershell
   docker-compose build --no-cache
   ```

4. **Start the containers**
   ```powershell
   docker-compose up -d
   ```

5. **Monitor the logs**
   ```powershell
   docker logs langflow-app -f
   ```

6. **Access Langflow**
   - Open: http://localhost:7860
   - Username: `admin`
   - Password: `admin123`

## Solution 2: Use Official Image with Backend Only

If you don't need the web UI and only want to use the API:

1. Update `docker-compose.yml` - set environment variable:
   ```yaml
   environment:
     - LANGFLOW_FRONTEND_PATH=/nonexistent  # Disable frontend
   ```

2. Restart:
   ```powershell
   docker-compose restart
   ```

3. Use API endpoints at http://localhost:7860/api/v1/

## Solution 3: Use Pre-built Image (Quick Fix)

Try using a specific version tag instead of `latest`:

1. Edit `docker-compose.yml` and change the image to:
   ```yaml
   image: langflowai/langflow:1.0.19  # Or latest stable version
   ```

2. Restart:
   ```powershell
   docker-compose down
   docker-compose pull
   docker-compose up -d
   ```

## Troubleshooting

### Docker Desktop Not Running
```powershell
# Check if Docker is running
docker ps

# If you get an error, restart Docker Desktop from Windows Start menu
```

### Build Fails
```powershell
# Clean everything and rebuild
docker-compose down -v
docker system prune -af
docker volume prune -f
docker-compose build --no-cache
docker-compose up -d
```

### Out of Disk Space
```powershell
# Remove unused Docker resources
docker system prune -af --volumes
```

### Port Already in Use
```powershell
# Check what's using port 7860
netstat -ano | findstr :7860

# Change the port in docker-compose.yml
ports:
  - "8080:7860"  # Change 7860 to another port
```

## Verification

Once containers are running, verify:

1. **Check container status**
   ```powershell
   docker ps
   ```
   Both `langflow-app` and `langflow-postgres` should be "healthy"

2. **Check logs**
   ```powershell
   docker logs langflow-app --tail 50
   ```
   Look for: "Welcome to Langflow" and "Open Langflow → http://localhost:7860"

3. **Test health endpoint**
   ```powershell
   curl http://localhost:7860/health
   ```
   Should return: `{"status":"ok"}`

4. **Test web interface**
   - Open browser: http://localhost:7860
   - Should see Langflow login page

## Current Configuration

Your `docker-compose.yml` is now configured to:
- Build Langflow from source (includes frontend)
- Use PostgreSQL for database
- Auto-login enabled
- CORS configured for development
- Volumes for persistent data

## Next Steps

1. Start Docker Desktop
2. Run: `docker-compose build`
3. Run: `docker-compose up -d`
4. Wait 2-3 minutes for initialization
5. Access: http://localhost:7860

Need help? Check the logs with: `docker logs langflow-app -f`


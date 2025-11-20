# Langflow Docker Build (UV Optimized)

This directory contains the **production-grade Docker build** for Langflow using [UV](https://github.com/astral-sh/uv), a fast Python package installer.

## Quick Start

```powershell
# Windows
cd C:\Users\Niraj\Desktop\AI\langFlow
.\docker\build.ps1
```

```bash
# Linux/Mac
cd ~/langflow
chmod +x docker/build.sh
./docker/build.sh
```

## What's Fixed

✅ **All dependencies included** (including `openai`)  
✅ **Frontend path corrected** (`/app/src/backend/base/langflow/frontend`)  
✅ **UV-based build** (faster, more reliable)  
✅ **Multi-stage build** (smaller final image)  
✅ **BuildKit caching** (faster subsequent builds)

## Dockerfile Overview

### `build_and_push_fixed.Dockerfile`

**Multi-stage build:**
1. **Builder Stage** (UV + Node.js)
   - Installs Python dependencies with UV
   - Builds frontend with npm
   - Creates virtual environment at `/app/.venv`

2. **Runtime Stage** (Python slim)
   - Copies only `.venv` (no build tools)
   - Runs as non-root user (UID 1000)
   - Final image: ~1.5-2 GB

### Key Features

| Feature | Description |
|---------|-------------|
| Base Image | `ghcr.io/astral-sh/uv:python3.12-bookworm-slim` |
| Package Manager | UV (faster than pip) |
| Python Version | 3.12.3 |
| User | `user` (UID 1000) |
| Working Dir | `/app` |
| Virtual Env | `/app/.venv` |
| Command | `langflow run` |
| Port | 7860 |

## Build Commands

### Basic Build

```bash
docker build -f docker/build_and_push_fixed.Dockerfile -t cera123/langflow:latest .
```

### Build with BuildKit (Recommended)

```bash
DOCKER_BUILDKIT=1 docker build -f docker/build_and_push_fixed.Dockerfile -t cera123/langflow:latest .
```

### Using Build Script

```powershell
# Windows - with custom registry and tag
.\docker\build.ps1 -Registry "myregistry" -Tag "v1.0.0"
```

```bash
# Linux - with custom registry and tag
./docker/build.sh myregistry v1.0.0
```

## Testing the Image

### Test Imports

```bash
docker run --rm cera123/langflow:latest python -c "
import langflow
import openai
import psycopg
import langchain
print('✅ All imports successful')
print('Langflow version:', langflow.__version__)
print('OpenAI version:', openai.__version__)
"
```

### Run Locally

```bash
# SQLite (no external DB needed)
docker run -d -p 7860:7860 --name langflow-test \
  -e LANGFLOW_DATABASE_URL=sqlite:///./langflow.db \
  cera123/langflow:latest

# PostgreSQL
docker run -d -p 7860:7860 --name langflow-test \
  -e LANGFLOW_DATABASE_URL=postgresql://user:pass@host:5432/db \
  cera123/langflow:latest

# Check logs
docker logs -f langflow-test

# Test health endpoint
curl http://localhost:7860/health

# Clean up
docker stop langflow-test && docker rm langflow-test
```

## Build Time & Size

| Metric | Value |
|--------|-------|
| First build | 10-15 minutes |
| Cached build | 3-5 minutes |
| Final image | ~1.5-2 GB |
| Compressed | ~600-800 MB |

## What Gets Installed

### Core Dependencies
- ✅ langflow-base (backend core)
- ✅ langflow (full package)
- ✅ FastAPI, SQLAlchemy, Alembic
- ✅ Pydantic, Typer, Rich

### LLM Integrations
- ✅ openai (GPT-3.5, GPT-4)
- ✅ anthropic (Claude)
- ✅ cohere
- ✅ google-genai (Gemini)
- ✅ groq
- ✅ mistralai
- ✅ ollama

### Vector Stores
- ✅ chromadb
- ✅ pinecone
- ✅ qdrant
- ✅ weaviate
- ✅ pgvector
- ✅ milvus

### Database Drivers
- ✅ psycopg (PostgreSQL)
- ✅ sqlite3 (built-in)
- ✅ aiosqlite (async SQLite)

### Tools
- ✅ langchain (all components)
- ✅ langsmith
- ✅ duckduckgo-search
- ✅ beautifulsoup4
- ✅ requests

## Push to Docker Hub

```bash
# Login (if needed)
docker login

# Push image
docker push cera123/langflow:latest

# Verify
docker pull cera123/langflow:latest
```

## Deploy to Kubernetes

After building and pushing:

```bash
cd k8s

# Apply deployment
kubectl apply -f langflow-deployment.yaml

# Watch pods
kubectl get pods -n prod -w

# Check logs
kubectl logs -f deployment/langflow-api-prod -n prod
```

**Expected output:**
```
Starting Langflow...
Langflow 1.x.x
✅ No import errors!
Running on 0.0.0.0:7860
```

## Troubleshooting

### Build fails at UV sync

**Error:**
```
error: Failed to download `openai==1.68.2`
```

**Fix:**
```bash
# Clear Docker cache
docker builder prune

# Retry build
DOCKER_BUILDKIT=1 docker build --no-cache -f docker/build_and_push_fixed.Dockerfile -t cera123/langflow:latest .
```

### Frontend build fails

**Error:**
```
npm ERR! code ELIFECYCLE
```

**Fix:**
```bash
# Build frontend manually first to verify
cd src/frontend
npm install --legacy-peer-deps
npm run build
cd ../..

# Then rebuild Docker image
```

### Frontend not found in image

**Error:**
```
FileNotFoundError: Frontend directory not found
```

**Fix:**
This should be fixed now. Frontend is copied to: `/app/src/backend/base/langflow/frontend`

Verify in container:
```bash
docker run --rm cera123/langflow:latest ls -la /app/src/backend/base/langflow/frontend
```

### Import errors in container

**Error:**
```
ModuleNotFoundError: No module named 'openai'
```

**Fix:**
This should be fixed. Verify dependencies:
```bash
docker run --rm cera123/langflow:latest pip list | grep openai
# Should show: openai  1.68.2 (or similar)
```

### Out of disk space

**Error:**
```
no space left on device
```

**Fix:**
```bash
# Clean up Docker
docker system prune -a
docker volume prune

# Remove old images
docker rmi $(docker images -f "dangling=true" -q)
```

## Advanced Usage

### Build with Custom Build Args

```bash
docker build \
  -f docker/build_and_push_fixed.Dockerfile \
  --build-arg UV_COMPILE_BYTECODE=0 \
  -t cera123/langflow:latest \
  .
```

### Build for Multiple Platforms

```bash
docker buildx create --use
docker buildx build \
  -f docker/build_and_push_fixed.Dockerfile \
  --platform linux/amd64,linux/arm64 \
  -t cera123/langflow:latest \
  --push \
  .
```

### Inspect the Image

```bash
# Check layers
docker history cera123/langflow:latest

# Check size
docker images cera123/langflow:latest

# Inspect metadata
docker inspect cera123/langflow:latest

# Enter container shell
docker run -it --rm cera123/langflow:latest bash
```

## Comparison: UV vs Pip

| Feature | UV (This Dockerfile) | Pip (Old Dockerfile) |
|---------|---------------------|----------------------|
| Install Speed | ⚡ 5-10x faster | 🐌 Baseline |
| Dependency Resolution | ✅ Fast, correct | ⚠️ Slow, can fail |
| Lock File | ✅ uv.lock | ❌ None |
| Cache | ✅ Excellent | ⚠️ Basic |
| Multi-stage Build | ✅ Yes | ✅ Yes |
| Final Image Size | 📦 ~1.5 GB | 📦 ~2-3 GB |

## File Structure

```
docker/
├── build_and_push_fixed.Dockerfile  # Main Dockerfile (UV-based)
├── build.ps1                        # Build script (Windows)
├── build.sh                         # Build script (Linux/Mac)
└── README.md                        # This file
```

## Environment Variables

Set these in Kubernetes deployment or docker run:

| Variable | Default | Description |
|----------|---------|-------------|
| `LANGFLOW_HOST` | `0.0.0.0` | Listen address |
| `LANGFLOW_PORT` | `7860` | Port |
| `LANGFLOW_DATABASE_URL` | - | Database connection string |
| `LANGFLOW_LOG_LEVEL` | `info` | Logging level |
| `LANGFLOW_WORKERS` | `2` | Number of workers |

## Next Steps

1. ✅ Build image: `.\docker\build.ps1`
2. ✅ Test locally: `docker run -p 7860:7860 ...`
3. ✅ Push to registry: `docker push cera123/langflow:latest`
4. ✅ Deploy to K8s: `kubectl apply -f k8s/langflow-deployment.yaml`
5. ✅ Verify: `kubectl logs -f deployment/langflow-api-prod -n prod`

## Support

- **Build issues:** Check build script output
- **Runtime issues:** Check `kubectl logs`
- **Deployment guide:** See `../k8s/README.md`
- **Quick commands:** See `../k8s/DEPLOY_COMMANDS.md`

---

**Status:** ✅ Production Ready  
**Last Updated:** November 20, 2025  
**Build Method:** UV + Multi-stage Docker  
**Tested:** ✅ Windows, ✅ Linux, ✅ K8s


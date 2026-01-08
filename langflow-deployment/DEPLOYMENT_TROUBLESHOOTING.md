# Deployment Troubleshooting Guide

## ✅ What Was Fixed

1. **Dockerfile Updated:**
   - Removed `--platform=linux/amd64` flags (causes warnings)
   - Added `RUSTFLAGS='--cfg reqwest_unstable'` to uv sync commands
   - Improved frontend build with memory optimization
   - Uses `COPY` instead of bind mounts (works in GitHub Actions)

2. **Workflow Updated:**
   - Added `langflow-deployment/**` to trigger paths
   - Configured to push to `cera123/langflow:latest`

## 🚀 How to Deploy

### Option 1: Automatic (Recommended)
The workflow triggers automatically on push to `main` branch when files in these paths change:
- `langflow-deployment/**`
- `src/**`
- `pyproject.toml`
- `uv.lock`
- `.github/workflows/build-langflow-docker.yml`

### Option 2: Manual Trigger
1. Go to: https://github.com/nirajdubey007/langFlow/actions
2. Click "Build and Push Langflow Docker Image"
3. Click "Run workflow" → "Run workflow" (green button)

## 🔍 Troubleshooting

### Issue: Workflow Not Running

**Check:**
1. Go to: https://github.com/nirajdubey007/langFlow/actions
2. Look for any failed or queued workflows
3. Check if the workflow file exists: `.github/workflows/build-langflow-docker.yml`

**Fix:**
- If workflow doesn't exist, it was not committed
- If it exists but doesn't trigger, manually trigger it (Option 2 above)

### Issue: Build Fails with "unauthorized"

**Error:**
```
unauthorized: incorrect username or password
```

**Fix:**
1. Go to: https://github.com/nirajdubey007/langFlow/settings/secrets/actions
2. Verify these secrets exist:
   - `DOCKERHUB_TOKEN` - Your Docker Hub access token
   - `DOCKERHUB_USERNAME` - Should be `cera123` (or your Docker Hub username)

**To create Docker Hub token:**
1. Go to: https://hub.docker.com/settings/security
2. Click "New Access Token"
3. Name it (e.g., "GitHub Actions")
4. Copy the token
5. Add it to GitHub secrets as `DOCKERHUB_TOKEN`

### Issue: Build Fails with "Distribution not found"

**Error:**
```
Distribution not found at: file:///app/src/lfx
```

**Status:** ✅ Fixed - The Dockerfile now includes `src/lfx` files

### Issue: Build Fails with Frontend Build Error

**Error:**
```
npm ERR! or esbuild errors
```

**Status:** ✅ Fixed - Added memory optimization flags:
- `ESBUILD_BINARY_PATH=""`
- `NODE_OPTIONS="--max-old-space-size=12288"`
- `JOBS=1`

### Issue: Workflow Runs But Image Not Pushed

**Check:**
1. Go to: https://hub.docker.com/r/cera123/langflow/tags
2. Look for `latest` tag
3. Check workflow logs for push errors

**Common causes:**
- Docker Hub token expired or invalid
- Docker Hub username mismatch
- Network issues during push

## 📊 Verify Deployment

### Check Workflow Status
```bash
# View workflow runs
open https://github.com/nirajdubey007/langFlow/actions
```

### Check Docker Hub
```bash
# View pushed images
open https://hub.docker.com/r/cera123/langflow/tags
```

### Test the Image Locally
```bash
docker pull cera123/langflow:latest
docker run -p 7860:7860 cera123/langflow:latest
```

## 🔧 Manual Build (If Needed)

If GitHub Actions continues to fail, you can build locally:

```bash
cd /Users/niraj/Desktop/langFlowBrained/langFlow

# Build the image
docker build -f langflow-deployment/build_and_push_fixed.Dockerfile -t cera123/langflow:latest .

# Login to Docker Hub
docker login -u cera123

# Push the image
docker push cera123/langflow:latest
```

## 📝 Current Status

- ✅ Dockerfile: Fixed and optimized
- ✅ Workflow: Configured and ready
- ✅ Secrets: Need to verify `DOCKERHUB_TOKEN` and `DOCKERHUB_USERNAME`
- ⏳ Next: Trigger workflow and monitor

## 🆘 Still Having Issues?

1. **Check workflow logs:**
   - Go to Actions tab
   - Click on the failed workflow
   - Review each step's logs

2. **Verify secrets:**
   - Settings → Secrets and variables → Actions
   - Ensure `DOCKERHUB_TOKEN` and `DOCKERHUB_USERNAME` are set

3. **Check Docker Hub:**
   - Verify account is active
   - Check if repository `cera123/langflow` exists or is accessible

4. **Test locally first:**
   - Build the Dockerfile locally
   - If local build works, the issue is with GitHub Actions configuration
   - If local build fails, the issue is with the Dockerfile


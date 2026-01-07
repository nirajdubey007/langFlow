# 🚀 GitHub Actions Setup - Automatic Docker Build & Push

This guide will help you set up automatic Docker image building and pushing to Docker Hub whenever you push code to GitHub.

## ✅ What Happens Automatically

When you push code to GitHub:
1. ✅ GitHub Actions automatically builds your Docker image
2. ✅ Includes all your customizations (Automate branding, dark theme, etc.)
3. ✅ Pushes to Docker Hub as `nirajdubey007/langflow:latest`
4. ✅ Also tags with version number from `pyproject.toml`

## 📋 Setup Steps (5 minutes)

### Step 1: Create Docker Hub Access Token

1. **Go to Docker Hub:**
   - Open: https://hub.docker.com/settings/security
   - Login with your Docker Hub account (create one if needed)

2. **Create new token:**
   - Click **"New Access Token"**
   - **Description:** `GitHub Actions`
   - **Permissions:** `Read, Write, Delete`
   - Click **"Generate"**

3. **Copy the token:**
   - ⚠️ **IMPORTANT:** Copy it immediately - you won't see it again!
   - Save it somewhere safe

### Step 2: Add Secrets to GitHub

1. **Go to your GitHub repository:**
   - https://github.com/nirajdubey007/langFlow

2. **Add secrets:**
   - Click **Settings** (top right of repo)
   - In left sidebar: **Secrets and variables** → **Actions**
   - Click **"New repository secret"**

3. **Add two secrets:**

   **Secret 1:**
   - **Name:** `DOCKERHUB_TOKEN`
   - **Secret:** [Paste the token from Step 1]
   - Click **"Add secret"**

   **Secret 2 (Optional - defaults to nirajdubey007):**
   - **Name:** `DOCKERHUB_USERNAME`
   - **Secret:** `nirajdubey007` (or your Docker Hub username)
   - Click **"Add secret"**

### Step 3: Push Your Code

```bash
cd /Users/niraj/Desktop/langFlowBrained/langFlow

# Check current status
git status

# Add all changes
git add .

# Commit
git commit -m "Add GitHub Actions workflow for automatic Docker builds"

# Push to GitHub
git push origin main
```

### Step 4: Verify Workflow Runs

1. **Go to GitHub repository:**
   - https://github.com/nirajdubey007/langFlow

2. **Click "Actions" tab** (top navigation)

3. **You should see:**
   - "Build and Push Langflow Docker Image" workflow
   - It should be running automatically (yellow dot)
   - Or click it and click "Run workflow" to trigger manually

4. **Wait for build:**
   - ⏱️ Takes 20-30 minutes
   - Watch progress in real-time
   - Green checkmark ✅ = Success!

### Step 5: Verify Image on Docker Hub

After successful build:
- Go to: https://hub.docker.com/r/nirajdubey007/langflow
- You should see:
  - `nirajdubey007/langflow:latest`
  - `nirajdubey007/langflow:1.7.2` (or current version)

## 🎯 What Triggers the Build

The workflow runs automatically when you push changes to:
- ✅ `Dockerfile`
- ✅ `src/**` (any frontend/backend changes)
- ✅ `pyproject.toml`
- ✅ `uv.lock`
- ✅ `.github/workflows/build-langflow-docker.yml`

**Or manually:**
- Go to Actions → "Build and Push Langflow Docker Image" → "Run workflow"

## 🔧 Using the Built Image

### Update docker-compose.yml

The `docker-compose.yml` is already configured to use:
```yaml
image: nirajdubey007/langflow:latest
```

### Pull and Run

```bash
# Pull the latest image
docker pull nirajdubey007/langflow:latest

# Or use docker-compose
cd langflow-deployment
docker-compose pull
docker-compose up -d
```

## 🐛 Troubleshooting

### "Workflow not running"
- Check that you pushed to `main` or `master` branch
- Verify workflow file exists: `.github/workflows/build-langflow-docker.yml`
- Check Actions tab for any errors

### "DOCKERHUB_TOKEN error"
- Verify secret name is exactly: `DOCKERHUB_TOKEN` (case-sensitive)
- Make sure token has Read, Write, Delete permissions
- Create a new token if needed

### "Authentication failed"
- Docker Hub token might be expired
- Create a new token and update the secret

### "Build failed"
- Check the workflow logs in GitHub Actions
- Common issues:
  - Out of disk space (workflow handles this automatically)
  - Frontend build errors (check `src/frontend/`)
  - Backend dependency issues (check `pyproject.toml`)

### "Image not found on Docker Hub"
- Make sure Docker Hub repository exists
- Repository should be: `nirajdubey007/langflow`
- It will be created automatically on first push

## 📊 Workflow Details

**What it does:**
1. Cleans up disk space (GitHub runners have limited space)
2. Checks out your code
3. Sets up Docker Buildx
4. Logs into Docker Hub
5. Extracts version from `pyproject.toml`
6. Builds Docker image with your customizations
7. Pushes to Docker Hub with tags:
   - `nirajdubey007/langflow:latest`
   - `nirajdubey007/langflow:<version>`

**Build time:** 20-30 minutes
**Platform:** linux/amd64

## 🎉 Success!

Once set up, every time you:
1. Make changes to your code
2. Push to GitHub
3. GitHub automatically builds and pushes your Docker image!

**No more manual builds needed!** 🚀

---

## 📝 Quick Reference

**GitHub Repository:** https://github.com/nirajdubey007/langFlow  
**Docker Hub Image:** https://hub.docker.com/r/nirajdubey007/langflow  
**Workflow:** `.github/workflows/build-langflow-docker.yml`

**Secrets needed:**
- `DOCKERHUB_TOKEN` (required)
- `DOCKERHUB_USERNAME` (optional, defaults to nirajdubey007)


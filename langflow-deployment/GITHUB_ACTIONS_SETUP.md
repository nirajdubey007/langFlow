# GitHub Actions Setup - Build Docker Image in the Cloud

Your GitHub Actions workflow is ready! Follow these steps to build your Docker image on GitHub's servers.

## ✅ What's Been Done

- ✅ Created `.github/workflows/build-langflow-docker.yml`
- ✅ Configured to build with your Dockerfile
- ✅ Will push to `cera123/langflow:latest` and `cera123/langflow:1.6.4`

## 📋 Setup Steps (5-10 minutes)

### Step 1: Create Docker Hub Access Token

1. **Go to Docker Hub:**
   - Open: https://hub.docker.com/settings/security

2. **Create new token:**
   - Click **"New Access Token"**
   - **Access Token Description:** `GitHub Actions`
   - **Access permissions:** `Read, Write, Delete`
   - Click **"Generate"**

3. **Copy the token:**
   - ⚠️ **IMPORTANT:** Copy and save it somewhere safe
   - You won't be able to see it again!

### Step 2: Add Token to GitHub

1. **Push your code to GitHub first** (if not already done):

```powershell
cd C:\Users\Niraj\lf\langflow

# Check if you have a GitHub repo
git remote -v

# If you see a GitHub URL, skip to step 2
# If not, create a repo on GitHub and add it:
# git remote add origin https://github.com/YOUR_USERNAME/langflow.git
```

2. **Go to your GitHub repository**

3. **Add the secret:**
   - Click **Settings** (top right)
   - In left sidebar: **Secrets and variables** → **Actions**
   - Click **"New repository secret"**
   - **Name:** `DOCKERHUB_TOKEN` (exactly this - case sensitive!)
   - **Secret:** Paste the token from Step 1
   - Click **"Add secret"**

### Step 3: Push Your Code

```powershell
cd C:\Users\Niraj\lf\langflow

# Add all files
git add .

# Commit
git commit -m "Add GitHub Actions workflow for Docker build"

# Push to GitHub
git push origin main
# Or if your branch is 'master':
# git push origin master
```

### Step 4: Run the Workflow

1. **Go to your GitHub repository**

2. **Click "Actions" tab** (top)

3. **Click "Build and Push Langflow Docker Image"** (left sidebar)

4. **Click "Run workflow"** button (right side)

5. **Select branch** (usually `main` or `master`)

6. **Click green "Run workflow"** button

### Step 5: Wait for Build

- ⏱️ Build takes **20-30 minutes**
- You'll see progress in real-time
- Green checkmark ✅ = Success!
- Red X ❌ = Failed (check logs)

### Step 6: Verify Image

After successful build, your image is on Docker Hub!

**Check it:**
- Go to: https://hub.docker.com/r/cera123/langflow
- You should see your image with tags `latest` and `1.6.4`

**Pull it anywhere:**
```bash
docker pull cera123/langflow:latest
docker run -d -p 7860:7860 cera123/langflow:latest
```

## 🎯 Quick Commands

All commands in one place:

```powershell
# Navigate to project
cd C:\Users\Niraj\lf\langflow

# Add and commit workflow
git add .
git commit -m "Add GitHub Actions Docker build workflow"

# Push to GitHub
git push origin main

# Then go to GitHub → Actions → Run workflow
```

## 🔧 Troubleshooting

### "No repository found"
- Make sure you've pushed code to GitHub
- Check: `git remote -v` shows a GitHub URL

### "Error: DOCKERHUB_TOKEN"
- Secret name must be exactly: `DOCKERHUB_TOKEN`
- Make sure you added it in: Settings → Secrets → Actions

### "Authentication failed"
- Docker Hub token might be wrong
- Create a new token and update the secret

### Build fails at frontend step
- This shouldn't happen on GitHub's servers (8GB RAM)
- Check the workflow logs for specific errors

## 📊 What Happens

1. **GitHub clones your code**
2. **Sets up Docker Buildx**
3. **Logs into Docker Hub** (with your token)
4. **Builds the image** (using GitHub's 8GB RAM servers)
5. **Pushes to Docker Hub** as:
   - `cera123/langflow:latest`
   - `cera123/langflow:1.6.4`

## 🎉 After Success

Your Docker image will be available worldwide!

**Use it anywhere:**

```bash
# Pull the image
docker pull cera123/langflow:latest

# Run it
docker run -d -p 7860:7860 cera123/langflow:latest

# Or use your docker-compose.yml
docker-compose up -d
```

## 💡 Future Builds

The workflow is configured to run:
- ✅ **Manually** - Click "Run workflow" in GitHub Actions
- ✅ **Automatically** - When you push changes to Dockerfile or source code

Just push changes and GitHub builds automatically!

## ❓ Need Help?

If you encounter any issues:
1. Check the GitHub Actions logs (click on the workflow run)
2. Verify Docker Hub token is correct
3. Make sure Docker Hub repository exists or is public

---

**Everything is ready! Just follow the steps above.** 🚀


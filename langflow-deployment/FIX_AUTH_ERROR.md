# 🔧 Fix Docker Hub Authentication Error

## ❌ Error Message
```
Error: Error response from daemon: Get "https://registry-1.docker.io/v2/": unauthorized: incorrect username or password
```

## ✅ Solution

This error means the Docker Hub token is either:
- Not set in GitHub Secrets
- Incorrect/expired
- Username doesn't match

### Step 1: Verify Your Docker Hub Username

1. **Go to Docker Hub:**
   - https://hub.docker.com/
   - Login and check your username (top right corner)
   - Make sure it matches what you're using

### Step 2: Create a New Docker Hub Access Token

1. **Go to Docker Hub Security Settings:**
   - https://hub.docker.com/settings/security

2. **Delete old tokens (if any):**
   - Scroll down to "Access Tokens"
   - Delete any old "GitHub Actions" tokens

3. **Create new token:**
   - Click **"New Access Token"**
   - **Description:** `GitHub Actions`
   - **Permissions:** `Read, Write, Delete` (all three!)
   - Click **"Generate"**

4. **Copy the token immediately:**
   - ⚠️ You won't see it again!
   - It looks like: `dckr_pat_xxxxxxxxxxxxxxxxxxxxx`

### Step 3: Add/Update Secret in GitHub

1. **Go to your GitHub repository:**
   - https://github.com/nirajdubey007/langFlow/settings/secrets/actions

2. **Check if `DOCKERHUB_TOKEN` exists:**
   - If it exists, click on it and **"Update"**
   - If it doesn't exist, click **"New repository secret"**

3. **Add/Update the secret:**
   - **Name:** `DOCKERHUB_TOKEN` (exactly this, case-sensitive!)
   - **Secret:** [Paste the token from Step 2]
   - Click **"Add secret"** or **"Update secret"**

4. **Optional: Add username secret (if different from nirajdubey007):**
   - Click **"New repository secret"**
   - **Name:** `DOCKERHUB_USERNAME`
   - **Secret:** Your Docker Hub username
   - Click **"Add secret"**

### Step 4: Re-run the Workflow

1. **Go to GitHub Actions:**
   - https://github.com/nirajdubey007/langFlow/actions

2. **Find the failed workflow run**

3. **Click "Re-run all jobs"** (or "Re-run failed jobs")

4. **Wait for it to complete** (20-30 minutes)

## 🔍 Verification Checklist

Before re-running, verify:

- [ ] Docker Hub username is correct
- [ ] New access token created with Read, Write, Delete permissions
- [ ] `DOCKERHUB_TOKEN` secret exists in GitHub (Settings → Secrets → Actions)
- [ ] Token value is correct (no extra spaces)
- [ ] If username is different, `DOCKERHUB_USERNAME` secret is set

## 🐛 Common Issues

### "Token doesn't have write permissions"
- Make sure token has **Read, Write, Delete** permissions
- Create a new token if needed

### "Username doesn't match"
- Check your Docker Hub username
- Add `DOCKERHUB_USERNAME` secret if different from `nirajdubey007`

### "Secret not found"
- Make sure secret name is exactly: `DOCKERHUB_TOKEN` (case-sensitive)
- Check it's in: Settings → Secrets and variables → Actions

### "Token expired"
- Docker Hub tokens don't expire, but they can be revoked
- Create a new token and update the secret

## ✅ Success Indicators

After fixing, you should see:
- ✅ "Login to Docker Hub" step succeeds
- ✅ "Build and push Docker image" step completes
- ✅ Image appears at: https://hub.docker.com/r/nirajdubey007/langflow

---

**After fixing, re-run the workflow and it should work!** 🚀


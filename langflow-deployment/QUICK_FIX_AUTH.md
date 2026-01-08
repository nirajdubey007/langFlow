# 🚨 Quick Fix: Docker Hub Authentication Error

## The Problem
```
Error: Error response from daemon: Get "https://registry-1.docker.io/v2/": unauthorized: incorrect username or password
```

This means either:
1. ❌ Token is wrong/expired
2. ❌ Username doesn't match the token
3. ❌ Token doesn't have correct permissions

## ✅ Step-by-Step Fix

### Step 1: Verify Your Docker Hub Username

1. **Go to Docker Hub:**
   - https://hub.docker.com/
   - **Login** (top right)
   - Check your **username** (it's in the URL or top right corner)
   - **Write it down!**

### Step 2: Delete Old Tokens

1. **Go to:** https://hub.docker.com/settings/security
2. **Scroll to "Access Tokens"**
3. **Delete ALL existing tokens** (especially "GitHub Actions" ones)
4. This ensures you start fresh

### Step 3: Create NEW Token

1. **Still on:** https://hub.docker.com/settings/security
2. **Click "New Access Token"**
3. **Fill in:**
   - **Description:** `GitHub Actions`
   - **Permissions:** ✅ **Read** ✅ **Write** ✅ **Delete** (ALL THREE!)
4. **Click "Generate"**
5. **COPY THE TOKEN IMMEDIATELY** (you won't see it again!)
   - It looks like: `dckr_pat_xxxxxxxxxxxxxxxxxxxxx`

### Step 4: Test Token Locally (Optional but Recommended)

```bash
cd /Users/niraj/Desktop/langFlowBrained/langFlow/langflow-deployment

# Test the token (replace with your actual token and username)
./test-docker-token.sh dckr_pat_YOUR_TOKEN_HERE nirajdubey007
```

If this fails, the token is wrong. Go back to Step 3.

### Step 5: Update GitHub Secret

1. **Go to:** https://github.com/nirajdubey007/langFlow/settings/secrets/actions

2. **Check if `DOCKERHUB_TOKEN` exists:**
   - If YES: Click on it → Click "Update" → Paste new token → "Update secret"
   - If NO: Click "New repository secret" → Name: `DOCKERHUB_TOKEN` → Paste token → "Add secret"

3. **Verify username (if different from nirajdubey007):**
   - Click "New repository secret" (or update if exists)
   - Name: `DOCKERHUB_USERNAME`
   - Value: Your Docker Hub username (from Step 1)
   - Click "Add secret"

### Step 6: Re-run Workflow

1. **Go to:** https://github.com/nirajdubey007/langFlow/actions
2. **Find the failed workflow**
3. **Click "Re-run all jobs"** (or "Re-run failed jobs")
4. **Wait 20-30 minutes**

## 🔍 Common Mistakes

### ❌ Wrong Secret Name
- Must be exactly: `DOCKERHUB_TOKEN` (case-sensitive!)
- Not: `dockerhub_token`, `DOCKER_HUB_TOKEN`, etc.

### ❌ Token Without Write Permission
- Token MUST have **Read, Write, Delete** permissions
- Just "Read" won't work!

### ❌ Username Mismatch
- Token must match the Docker Hub username
- If your username is different, add `DOCKERHUB_USERNAME` secret

### ❌ Copy/Paste Errors
- Make sure no extra spaces before/after token
- Copy the entire token (starts with `dckr_pat_`)

## ✅ Verification Checklist

Before re-running, verify:

- [ ] Docker Hub username is correct (from Step 1)
- [ ] Old tokens deleted
- [ ] New token created with **Read, Write, Delete** permissions
- [ ] Token copied correctly (no spaces)
- [ ] `DOCKERHUB_TOKEN` secret updated in GitHub
- [ ] If username ≠ nirajdubey007, `DOCKERHUB_USERNAME` secret is set
- [ ] Token tested locally (optional but recommended)

## 🎯 Still Not Working?

If it still fails after following all steps:

1. **Double-check username:**
   - Go to: https://hub.docker.com/settings/general
   - Verify your username

2. **Create token again:**
   - Delete the token
   - Create a completely new one
   - Make sure permissions are **Read, Write, Delete**

3. **Check GitHub secret:**
   - Go to: https://github.com/nirajdubey007/langFlow/settings/secrets/actions
   - Verify `DOCKERHUB_TOKEN` exists and is correct
   - Try deleting and re-adding it

4. **Verify workflow file:**
   - The workflow should use: `${{ secrets.DOCKERHUB_TOKEN }}`
   - Check: `.github/workflows/build-langflow-docker.yml`

---

**Follow these steps exactly and it will work!** 🚀



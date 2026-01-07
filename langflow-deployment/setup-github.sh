#!/bin/bash
# Setup GitHub Actions for Automatic Docker Builds

set -e

echo "========================================"
echo "GitHub Actions Setup Helper"
echo "========================================"
echo ""

# Check if we're in a git repo
echo "Step 1: Checking Git repository..."
if git remote -v | grep -q "github.com"; then
    echo "[OK] GitHub repository found"
    git remote -v
else
    echo "[WARN] No GitHub repository detected"
    echo ""
    echo "You need to:"
    echo "1. Create a repository on GitHub.com"
    echo "2. Run: git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
    echo "3. Run this script again"
    echo ""
    exit 1
fi

# Check if workflow file exists
echo ""
echo "Step 2: Checking workflow file..."
if [ -f ".github/workflows/build-langflow-docker.yml" ]; then
    echo "[OK] Workflow file exists"
else
    echo "[FAIL] Workflow file not found"
    exit 1
fi

# Instructions for Docker Hub Token
echo ""
echo "========================================"
echo "Step 3: CREATE DOCKER HUB TOKEN"
echo "========================================"
echo ""
echo "1. Open this URL in your browser:"
echo "   https://hub.docker.com/settings/security"
echo ""
echo "2. Click 'New Access Token'"
echo "   - Description: GitHub Actions"
echo "   - Permissions: Read, Write, Delete"
echo ""
echo "3. Click 'Generate' and COPY the token"
echo ""
read -p "Press Enter after you've copied the token..."

# Instructions for adding secret to GitHub
echo ""
echo "========================================"
echo "Step 4: ADD SECRET TO GITHUB"
echo "========================================"
echo ""
echo "1. Open your GitHub repository in browser:"
echo "   https://github.com/nirajdubey007/langFlow"
echo ""
echo "2. Go to: Settings → Secrets and variables → Actions"
echo ""
echo "3. Click 'New repository secret'"
echo "   - Name: DOCKERHUB_TOKEN"
echo "   - Secret: [paste the token you copied]"
echo ""
echo "4. Click 'Add secret'"
echo ""
read -p "Press Enter after you've added the secret..."

# Commit and push
echo ""
echo "========================================"
echo "Step 5: PUSHING TO GITHUB"
echo "========================================"
echo ""

echo "Adding files..."
git add .

echo "Committing..."
git commit -m "Add GitHub Actions workflow for automatic Docker builds" || echo "[INFO] No new changes to commit (that's ok)"

echo ""
echo "Pushing to GitHub..."
current_branch=$(git branch --show-current)
git push origin "$current_branch"

if [ $? -eq 0 ]; then
    echo "[OK] Pushed to GitHub successfully!"
else
    echo "[WARN] Push may have failed"
    echo "Try manually: git push origin $current_branch"
fi

# Final instructions
echo ""
echo "========================================"
echo "SUCCESS! Ready to Build"
echo "========================================"
echo ""
echo "NEXT STEPS:"
echo ""
echo "1. Open your GitHub repository:"
echo "   https://github.com/nirajdubey007/langFlow"
echo ""
echo "2. Click 'Actions' tab at the top"
echo ""
echo "3. Click 'Build and Push Langflow Docker Image'"
echo ""
echo "4. Click 'Run workflow' (green button)"
echo ""
echo "5. Wait 20-30 minutes for the build to complete"
echo ""
echo "========================================"
echo "After build completes, your image will be at:"
echo "  https://hub.docker.com/r/nirajdubey007/langflow"
echo "========================================"
echo ""
echo "See GITHUB_SETUP.md for detailed instructions"
echo ""


# Setup GitHub Actions for Cloud Docker Build
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "GitHub Actions Setup Helper" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if we're in a git repo
Write-Host "Step 1: Checking Git repository..." -ForegroundColor Yellow
$gitRemote = git remote -v 2>&1
if ($LASTEXITCODE -eq 0 -and $gitRemote -match "github.com") {
    Write-Host "[OK] GitHub repository found" -ForegroundColor Green
    Write-Host $gitRemote
} else {
    Write-Host "[WARN] No GitHub repository detected" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You need to:" -ForegroundColor White
    Write-Host "1. Create a repository on GitHub.com" -ForegroundColor White
    Write-Host "2. Run: git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git" -ForegroundColor Cyan
    Write-Host "3. Run this script again" -ForegroundColor White
    Write-Host ""
    exit 1
}

# Step 2: Check if workflow file exists
Write-Host ""
Write-Host "Step 2: Checking workflow file..." -ForegroundColor Yellow
if (Test-Path ".github\workflows\build-langflow-docker.yml") {
    Write-Host "[OK] Workflow file created" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Workflow file not found" -ForegroundColor Red
    exit 1
}

# Step 3: Instructions for Docker Hub Token
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 3: CREATE DOCKER HUB TOKEN" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Open this URL in your browser:" -ForegroundColor White
Write-Host "   https://hub.docker.com/settings/security" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Click 'New Access Token'" -ForegroundColor White
Write-Host "   - Description: GitHub Actions" -ForegroundColor Gray
Write-Host "   - Permissions: Read, Write, Delete" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Click 'Generate' and COPY the token" -ForegroundColor White
Write-Host ""
Write-Host "Press Enter after you've copied the token..." -ForegroundColor Yellow
Read-Host

# Step 4: Instructions for adding secret to GitHub
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 4: ADD SECRET TO GITHUB" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Open your GitHub repository in browser" -ForegroundColor White
Write-Host ""
Write-Host "2. Go to: Settings → Secrets and variables → Actions" -ForegroundColor White
Write-Host ""
Write-Host "3. Click 'New repository secret'" -ForegroundColor White
Write-Host "   - Name: DOCKERHUB_TOKEN" -ForegroundColor Cyan
Write-Host "   - Secret: [paste the token you copied]" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Click 'Add secret'" -ForegroundColor White
Write-Host ""
Write-Host "Press Enter after you've added the secret..." -ForegroundColor Yellow
Read-Host

# Step 5: Commit and push
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 5: PUSHING TO GITHUB" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Adding files..." -ForegroundColor Gray
git add .

Write-Host "Committing..." -ForegroundColor Gray
git commit -m "Add GitHub Actions workflow for Docker build"

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Changes committed" -ForegroundColor Green
} else {
    Write-Host "[INFO] No new changes to commit (that's ok)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Pushing to GitHub..." -ForegroundColor Gray

# Detect default branch
$currentBranch = git branch --show-current

git push origin $currentBranch

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Pushed to GitHub successfully!" -ForegroundColor Green
} else {
    Write-Host "[WARN] Push may have failed" -ForegroundColor Yellow
    Write-Host "Try manually: git push origin $currentBranch" -ForegroundColor Cyan
}

# Step 6: Final instructions
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "SUCCESS! Ready to Build" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Open your GitHub repository in browser" -ForegroundColor White
Write-Host ""
Write-Host "2. Click 'Actions' tab at the top" -ForegroundColor White
Write-Host ""
Write-Host "3. Click 'Build and Push Langflow Docker Image'" -ForegroundColor White
Write-Host ""
Write-Host "4. Click 'Run workflow' (green button)" -ForegroundColor White
Write-Host ""
Write-Host "5. Click 'Run workflow' again to confirm" -ForegroundColor White
Write-Host ""
Write-Host "6. Wait 20-30 minutes for the build to complete" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "After build completes, your image will be at:" -ForegroundColor Yellow
Write-Host "  https://hub.docker.com/r/cera123/langflow" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "See GITHUB_ACTIONS_SETUP.md for detailed instructions" -ForegroundColor Gray
Write-Host ""


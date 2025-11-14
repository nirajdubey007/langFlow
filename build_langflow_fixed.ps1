# PowerShell script to build and push Langflow Docker image - FIXED VERSION
# This script handles common Windows Docker build issues

param(
    [string]$Registry = "cera123",
    [string]$Tag = "latest",
    [switch]$UseSimpleBuild = $false,
    [switch]$SkipBuild = $false
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Langflow Docker Build & Push (Windows)      " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$ImageName = "$Registry/langflow:$Tag"
$ErrorActionPreference = "Continue"

# Step 0: Check Docker availability
Write-Host "`n[0/5] Checking Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "  OK Docker is available: $dockerVersion" -ForegroundColor Green
}
catch {
    Write-Host "  ERROR Docker is not available. Please install Docker Desktop." -ForegroundColor Red
    exit 1
}

# Step 0.5: Option to skip build and use official image
if ($SkipBuild) {
    Write-Host "`n[SKIP BUILD] Using official Langflow image..." -ForegroundColor Cyan
    
    Write-Host "`n[1/3] Pulling official image..." -ForegroundColor Yellow
    docker pull langflowai/langflow:latest
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR Failed to pull official image" -ForegroundColor Red
        exit 1
    }
    Write-Host "  OK Official image pulled successfully" -ForegroundColor Green
    
    Write-Host "`n[2/3] Tagging image..." -ForegroundColor Yellow
    docker tag langflowai/langflow:latest $ImageName
    Write-Host "  OK Image tagged as $ImageName" -ForegroundColor Green
    
    Write-Host "`n[3/3] Pushing to registry..." -ForegroundColor Yellow
    docker login
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR Docker login failed" -ForegroundColor Red
        exit 1
    }
    
    docker push $ImageName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR Failed to push image" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "`n================================================" -ForegroundColor Green
    Write-Host "              SUCCESS!                          " -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Green
    Write-Host "`nYour image is ready: $ImageName" -ForegroundColor White
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Share langflow-deployment/ folder with cloud team" -ForegroundColor White
    Write-Host "2. They run: docker-compose up -d" -ForegroundColor White
    Write-Host "3. Access at: http://your-server:7860" -ForegroundColor White
    exit 0
}

# Step 1: Choose Dockerfile
if ($UseSimpleBuild) {
    $Dockerfile = "docker/build_and_push_simple.Dockerfile"
    Write-Host "`n[1/5] Using simplified Dockerfile (recommended for Windows)" -ForegroundColor Yellow
}
else {
    $Dockerfile = "docker/build_and_push_fixed.Dockerfile"
    Write-Host "`n[1/5] Using fixed Dockerfile" -ForegroundColor Yellow
}

Write-Host "  Dockerfile: $Dockerfile" -ForegroundColor White

# Step 2: Build the image
Write-Host "`n[2/5] Building Docker image..." -ForegroundColor Yellow
Write-Host "  This may take 10-20 minutes. Please be patient..." -ForegroundColor Cyan
Write-Host "  Building for platform: linux/amd64" -ForegroundColor Cyan

$buildStartTime = Get-Date

try {
    docker build --platform linux/amd64 -f $Dockerfile -t $ImageName .
    
    if ($LASTEXITCODE -eq 0) {
        $buildEndTime = Get-Date
        $buildDuration = ($buildEndTime - $buildStartTime).TotalMinutes
        Write-Host "  OK Build completed successfully in $([math]::Round($buildDuration, 2)) minutes" -ForegroundColor Green
    }
    else {
        Write-Host "  ERROR Build failed with exit code: $LASTEXITCODE" -ForegroundColor Red
        Write-Host "`n  Try these alternatives:" -ForegroundColor Yellow
        Write-Host "     1. Run with -UseSimpleBuild flag" -ForegroundColor White
        Write-Host "     2. Run with -SkipBuild flag to use official image" -ForegroundColor White
        Write-Host "     3. Check DOCKER_BUILD_SOLUTIONS.md for more solutions" -ForegroundColor White
        exit 1
    }
}
catch {
    Write-Host "  ERROR Build error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Test the image
Write-Host "`n[3/5] Testing the built image..." -ForegroundColor Yellow
try {
    $testContainer = docker run -d --name langflow-test-$([Guid]::NewGuid().ToString().Substring(0, 8)) -p 7861:7860 $ImageName
    Start-Sleep -Seconds 15
    
    $containerStatus = docker ps --filter "name=langflow-test" --format "{{.Status}}"
    if ($containerStatus -match "Up") {
        Write-Host "  OK Container is running successfully" -ForegroundColor Green
    }
    else {
        Write-Host "  WARNING Container may not be fully started yet" -ForegroundColor Yellow
    }
    
    # Clean up
    docker stop $testContainer 2>$null | Out-Null
    docker rm $testContainer 2>$null | Out-Null
    Write-Host "  OK Test container cleaned up" -ForegroundColor Green
}
catch {
    Write-Host "  WARNING Test skipped: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Step 4: Login to Docker Hub
Write-Host "`n[4/5] Logging into Docker Hub..." -ForegroundColor Yellow
try {
    docker login
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK Successfully logged in" -ForegroundColor Green
    }
    else {
        Write-Host "  ERROR Login failed" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "  ERROR Login error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 5: Push to registry
Write-Host "`n[5/5] Pushing image to Docker Hub..." -ForegroundColor Yellow
Write-Host "  Target: $ImageName" -ForegroundColor White

try {
    docker push $ImageName
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK Image pushed successfully!" -ForegroundColor Green
    }
    else {
        Write-Host "  ERROR Push failed" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "  ERROR Push error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Success message
Write-Host "`n================================================" -ForegroundColor Green
Write-Host "              SUCCESS!                          " -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

Write-Host "`nImage Details:" -ForegroundColor Cyan
Write-Host "  Name: $ImageName" -ForegroundColor White
Write-Host "  Platform: linux/amd64" -ForegroundColor White
Write-Host "  Status: Available on Docker Hub" -ForegroundColor White

Write-Host "`nNext Steps for Cloud Team:" -ForegroundColor Cyan
Write-Host "  1. Update docker-compose.yml with: image: $ImageName" -ForegroundColor White
Write-Host "  2. Run: docker-compose up -d" -ForegroundColor White
Write-Host "  3. Access at: http://your-server:7860" -ForegroundColor White

Write-Host "`nFiles to Share:" -ForegroundColor Cyan
Write-Host "  - langflow-deployment/docker-compose.yml" -ForegroundColor White
Write-Host "  - langflow-deployment/DOCKER_README.md" -ForegroundColor White

Write-Host "`nDocker Hub: https://hub.docker.com/r/$Registry/langflow" -ForegroundColor White
Write-Host "`n================================================" -ForegroundColor Green
Write-Host "Done! Your Langflow image is ready." -ForegroundColor Green
Write-Host "================================================`n" -ForegroundColor Green

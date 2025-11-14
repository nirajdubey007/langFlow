# Build and Test Langflow Docker Image
# This script builds the Docker image and tests it locally

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Langflow Docker Build and Test Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$DOCKER_USERNAME = "cera123"
$IMAGE_NAME = "langflow"
$TAG = "test-local"
$FULL_IMAGE_NAME = "${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"

# Check if Docker is running
Write-Host "Checking Docker status..." -ForegroundColor Yellow
try {
    docker info | Out-Null
    Write-Host "[OK] Docker is running" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Navigate to project root
$PROJECT_ROOT = Split-Path -Parent $PSScriptRoot
Set-Location $PROJECT_ROOT
Write-Host "[OK] Working directory: $PROJECT_ROOT" -ForegroundColor Green
Write-Host ""

# Build the Docker image
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building Docker Image..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Image: $FULL_IMAGE_NAME" -ForegroundColor Yellow
Write-Host ""

$startTime = Get-Date
docker build `
    -f langflow-deployment/build_and_push_fixed.Dockerfile `
    -t $FULL_IMAGE_NAME `
    --progress=plain `
    .

if ($LASTEXITCODE -eq 0) {
    $endTime = Get-Date
    $duration = $endTime - $startTime
    Write-Host ""
    Write-Host "[SUCCESS] Build completed successfully in $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[FAIL] Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Docker Image Details" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
docker images $FULL_IMAGE_NAME --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting Test Container..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Stop any existing test container
docker rm -f langflow-test 2>$null

# Run the container
Write-Host "Starting container on http://localhost:7860" -ForegroundColor Yellow
docker run -d `
    --name langflow-test `
    -p 7860:7860 `
    -e LANGFLOW_LOG_LEVEL=INFO `
    $FULL_IMAGE_NAME

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Container started successfully" -ForegroundColor Green
    Write-Host ""
    Write-Host "Container Logs (first 10 seconds):" -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    docker logs langflow-test
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Test Results" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    $containerId = docker ps -q -f name=langflow-test
    Write-Host "[OK] Container ID: $containerId" -ForegroundColor Green
    Write-Host "[OK] Access Langflow at: http://localhost:7860" -ForegroundColor Green
    Write-Host ""
    Write-Host "Useful Commands:" -ForegroundColor Yellow
    Write-Host "  View logs:        docker logs -f langflow-test" -ForegroundColor White
    Write-Host "  Stop container:   docker stop langflow-test" -ForegroundColor White
    Write-Host "  Remove container: docker rm -f langflow-test" -ForegroundColor White
    Write-Host "  Push to hub:      .\push-to-hub.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "To test the application, open: http://localhost:7860" -ForegroundColor Cyan
} else {
    Write-Host "[FAIL] Failed to start container" -ForegroundColor Red
    exit 1
}

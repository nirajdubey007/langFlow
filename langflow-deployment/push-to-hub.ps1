# Push Langflow Docker Image to Docker Hub
# Run this after successfully building and testing locally

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Push Langflow Image to Docker Hub" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$DOCKER_USERNAME = "cera123"
$IMAGE_NAME = "langflow"
$LOCAL_TAG = "test-local"
$PUSH_TAG = "latest"
$LOCAL_IMAGE = "${DOCKER_USERNAME}/${IMAGE_NAME}:${LOCAL_TAG}"
$PUSH_IMAGE = "${DOCKER_USERNAME}/${IMAGE_NAME}:${PUSH_TAG}"

# Check if local image exists
Write-Host "Checking for local image: $LOCAL_IMAGE" -ForegroundColor Yellow
$imageExists = docker images -q $LOCAL_IMAGE

if (-not $imageExists) {
    Write-Host "[FAIL] Local image not found. Please build the image first using build-and-test.ps1" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Local image found" -ForegroundColor Green
Write-Host ""

# Check Docker Hub login
Write-Host "Checking Docker Hub authentication..." -ForegroundColor Yellow
$loginCheck = docker info 2>&1 | Select-String "Username"
if ($loginCheck) {
    Write-Host "[OK] Already logged in to Docker Hub" -ForegroundColor Green
} else {
    Write-Host "Please login to Docker Hub:" -ForegroundColor Yellow
    docker login
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[FAIL] Docker Hub login failed" -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# Tag for latest
Write-Host "Tagging image as 'latest'..." -ForegroundColor Yellow
docker tag $LOCAL_IMAGE $PUSH_IMAGE
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Image tagged successfully" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Failed to tag image" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Also tag with version from pyproject.toml if available
$PROJECT_ROOT = Split-Path -Parent $PSScriptRoot
$pyprojectPath = Join-Path $PROJECT_ROOT "pyproject.toml"
if (Test-Path $pyprojectPath) {
    $version = (Get-Content $pyprojectPath | Select-String 'version = "(.+)"').Matches.Groups[1].Value
    if ($version) {
        $VERSION_IMAGE = "${DOCKER_USERNAME}/${IMAGE_NAME}:${version}"
        Write-Host "Tagging image with version: $version" -ForegroundColor Yellow
        docker tag $LOCAL_IMAGE $VERSION_IMAGE
        Write-Host "[OK] Version tag created: $VERSION_IMAGE" -ForegroundColor Green
    }
}
Write-Host ""

# Push to Docker Hub
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Pushing to Docker Hub..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Pushing: $PUSH_IMAGE" -ForegroundColor Yellow
docker push $PUSH_IMAGE

if ($LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] Successfully pushed to Docker Hub!" -ForegroundColor Green
    
    # Push version tag if it exists
    if ($VERSION_IMAGE) {
        Write-Host ""
        Write-Host "Pushing version tag: $VERSION_IMAGE" -ForegroundColor Yellow
        docker push $VERSION_IMAGE
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Version tag pushed successfully!" -ForegroundColor Green
        }
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "SUCCESS!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Your image is now available at:" -ForegroundColor Yellow
    Write-Host "  https://hub.docker.com/r/$DOCKER_USERNAME/$IMAGE_NAME" -ForegroundColor White
    Write-Host ""
    Write-Host "To pull and run from anywhere:" -ForegroundColor Yellow
    Write-Host "  docker pull $PUSH_IMAGE" -ForegroundColor White
    Write-Host "  docker run -p 7860:7860 $PUSH_IMAGE" -ForegroundColor White
} else {
    Write-Host "[FAIL] Failed to push image to Docker Hub" -ForegroundColor Red
    exit 1
}

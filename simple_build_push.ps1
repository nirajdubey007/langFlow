# Simple PowerShell script to tag and push Langflow image
param(
    [string]$Registry = "cera123",
    [string]$Tag = "latest"
)

Write-Host "Simple Langflow Image Tag and Push" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green

$ImageName = "$Registry/langflow:$Tag"

Write-Host "1. Pulling the official Langflow image..." -ForegroundColor Yellow
try {
    docker pull langflowai/langflow:latest
    Write-Host "✓ Official image pulled successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to pull official image: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "2. Tagging image as: $ImageName" -ForegroundColor Yellow
try {
    docker tag langflowai/langflow:latest $ImageName
    Write-Host "✓ Image tagged successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to tag image: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "3. Logging into Docker Hub..." -ForegroundColor Yellow
try {
    docker login
    Write-Host "✓ Docker login successful" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "4. Pushing image to registry..." -ForegroundColor Yellow
try {
    docker push $ImageName
    Write-Host "✓ Image pushed successfully!" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to push image: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n🎉 SUCCESS!" -ForegroundColor Green
Write-Host "Your Langflow image is now available at: $ImageName" -ForegroundColor White
Write-Host "`n📋 Instructions for cloud team:" -ForegroundColor Cyan
Write-Host "1. Update docker-compose.yml to use: image: $ImageName" -ForegroundColor White
Write-Host "2. Run: docker-compose up -d" -ForegroundColor White
Write-Host "3. Access at: http://your-server:7860" -ForegroundColor White

# Quick script to check Docker build status

Write-Host "`n=== Docker Build Status Check ===" -ForegroundColor Cyan

# Check if image exists
Write-Host "`n1. Checking for built image..." -ForegroundColor Yellow
$image = docker images cera123/langflow:latest --format "{{.Repository}}:{{.Tag}}" 2>$null

if ($image) {
    Write-Host "   ✓ Image found: $image" -ForegroundColor Green
    
    # Get image details
    $imageDetails = docker images cera123/langflow:latest --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    Write-Host "`n   Image Details:" -ForegroundColor Cyan
    Write-Host "   $imageDetails" -ForegroundColor White
    
    Write-Host "`n   Next steps:" -ForegroundColor Cyan
    Write-Host "   1. docker login" -ForegroundColor White
    Write-Host "   2. docker push cera123/langflow:latest" -ForegroundColor White
} else {
    Write-Host "   ✗ Image not found yet" -ForegroundColor Red
    Write-Host "   Build may still be in progress..." -ForegroundColor Yellow
}

# Check running containers
Write-Host "`n2. Checking Docker processes..." -ForegroundColor Yellow
$containers = docker ps --format "table {{.Names}}\t{{.Status}}" 2>$null
if ($containers) {
    Write-Host "   Running containers:" -ForegroundColor White
    Write-Host "   $containers" -ForegroundColor White
} else {
    Write-Host "   No running containers" -ForegroundColor White
}

# Check Docker system
Write-Host "`n3. Docker system info..." -ForegroundColor Yellow
$dockerInfo = docker system df --format "table {{.Type}}\t{{.TotalCount}}\t{{.Size}}" 2>$null
if ($dockerInfo) {
    Write-Host "   $dockerInfo" -ForegroundColor White
}

Write-Host "`n=================================`n" -ForegroundColor Cyan



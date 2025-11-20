# Simple build script without uv sync
param(
    [string]$Registry = "magittitconsultancy",
    [string]$Tag = "latest"
)

Write-Host "Building Langflow Docker Image (Simplified)" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

$ImageName = "$Registry/langflow:$Tag"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

Write-Host "Project Root: $ProjectRoot" -ForegroundColor Yellow
Write-Host "Image Name: $ImageName" -ForegroundColor Yellow

# Check if required files exist
$RequiredFiles = @(
    "$ProjectRoot\pyproject.toml",
    "$ProjectRoot\README.md",
    "$ProjectRoot\src\frontend\package.json",
    "$ProjectRoot\src\backend\base\pyproject.toml"
)

foreach ($file in $RequiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "ERROR: Required file not found: $file" -ForegroundColor Red
        exit 1
    }
}

Write-Host "All required files found!" -ForegroundColor Green

# Build the image
Write-Host "`nBuilding Docker image..." -ForegroundColor Yellow
try {
    docker build `
        -f "$PSScriptRoot\Dockerfile.simple" `
        -t $ImageName `
        $ProjectRoot

    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✓ Docker build completed successfully!" -ForegroundColor Green
        Write-Host "Image: $ImageName" -ForegroundColor Cyan
    } else {
        Write-Host "`n✗ Docker build failed!" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Docker build error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test the image
Write-Host "`nTesting the built image..." -ForegroundColor Yellow
try {
    $testContainer = docker run -d --name langflow-test -p 7861:7860 $ImageName
    Start-Sleep -Seconds 15

    $containerStatus = docker ps --filter "name=langflow-test" --format "{{.Status}}"
    if ($containerStatus -match "Up") {
        Write-Host "✓ Container is running successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Container may not be fully started yet" -ForegroundColor Yellow
        docker logs langflow-test
    }

    # Clean up test container
    docker stop langflow-test 2>$null
    docker rm langflow-test 2>$null
    Write-Host "✓ Test container cleaned up" -ForegroundColor Green

} catch {
    Write-Host "⚠️ Local test failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n🎉 SUCCESS!" -ForegroundColor Green
Write-Host "Your Langflow image is ready: $ImageName" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Test locally: docker run -p 7860:7860 $ImageName" -ForegroundColor White
Write-Host "2. Push to registry: docker push $ImageName" -ForegroundColor White
Write-Host "3. Deploy to AKS: kubectl set image deployment/langflow-api-prod langflow=$ImageName -n prod" -ForegroundColor White


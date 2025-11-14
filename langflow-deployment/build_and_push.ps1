# PowerShell script to build and push Langflow Docker image
param(
    [string]$Registry = "cera123",
    [string]$Tag = "latest"
)

Write-Host "Building and Pushing Langflow Docker Image" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

$ImageName = "$Registry/langflow:$Tag"

Write-Host "1. Building Docker image: $ImageName" -ForegroundColor Yellow
try {
    docker build -f docker/build_and_push_fixed.Dockerfile -t $ImageName .
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Docker build completed successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Docker build failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Docker build error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "2. Testing the built image locally" -ForegroundColor Yellow
try {
    # Quick test to see if the image runs
    $testContainer = docker run -d --name langflow-test -p 7861:7860 $ImageName
    Start-Sleep -Seconds 10

    # Check if container is running
    $containerStatus = docker ps --filter "name=langflow-test" --format "{{.Status}}"
    if ($containerStatus -match "Up") {
        Write-Host "✓ Container is running successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Container may not be fully started yet" -ForegroundColor Yellow
    }

    # Clean up test container
    docker stop langflow-test 2>$null
    docker rm langflow-test 2>$null
    Write-Host "✓ Test container cleaned up" -ForegroundColor Green

} catch {
    Write-Host "⚠️ Local test failed, but continuing with push: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "3. Logging into Docker Hub" -ForegroundColor Yellow
try {
    docker login
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Docker login successful" -ForegroundColor Green
    } else {
        Write-Host "✗ Docker login failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Docker login error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "4. Pushing image to registry: $ImageName" -ForegroundColor Yellow
try {
    docker push $ImageName
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Image pushed successfully to $ImageName" -ForegroundColor Green
    } else {
        Write-Host "✗ Image push failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Image push error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n🎉 SUCCESS!" -ForegroundColor Green
Write-Host "Your Langflow image is now available at: $ImageName" -ForegroundColor White
Write-Host "`n📋 Next steps for cloud team:" -ForegroundColor Cyan
Write-Host "1. Update docker-compose.yml to use: image: $ImageName" -ForegroundColor White
Write-Host "2. Run: docker-compose up -d" -ForegroundColor White
Write-Host "3. Access at: http://your-server:7860" -ForegroundColor White

Write-Host "`n🔗 Share this information with your cloud team:" -ForegroundColor Yellow
Write-Host "- Image: $ImageName" -ForegroundColor White
Write-Host "- Configuration files in langflow-deployment/ folder" -ForegroundColor White
Write-Host "- DOCKER_README.md for setup instructions" -ForegroundColor White

# Script to check Docker, start it if needed, and build Langflow

Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         Docker Desktop Check & Build Script          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# Step 1: Check if Docker is running
Write-Host "`n[1/6] Checking Docker Desktop status..." -ForegroundColor Yellow

try {
    $null = docker ps 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Docker Desktop is running!" -ForegroundColor Green
    } else {
        throw "Docker not responding"
    }
} catch {
    Write-Host "  ✗ Docker Desktop is NOT running" -ForegroundColor Red
    Write-Host "`n  Starting Docker Desktop..." -ForegroundColor Yellow
    
    # Try to start Docker Desktop
    $dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    
    if (Test-Path $dockerPath) {
        Start-Process $dockerPath
        Write-Host "  Docker Desktop is starting..." -ForegroundColor Cyan
        Write-Host "  Please wait for Docker to fully start (this may take 30-60 seconds)..." -ForegroundColor Cyan
        
        # Wait for Docker to be ready
        $maxAttempts = 30
        $attempt = 0
        $dockerReady = $false
        
        Write-Host "`n  Waiting for Docker Engine to be ready..." -ForegroundColor Yellow
        while ($attempt -lt $maxAttempts -and -not $dockerReady) {
            $attempt++
            Start-Sleep -Seconds 2
            
            try {
                $null = docker ps 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $dockerReady = $true
                    Write-Host "  ✓ Docker is ready!" -ForegroundColor Green
                } else {
                    Write-Host "  ⏳ Attempt $attempt/$maxAttempts..." -ForegroundColor Gray
                }
            } catch {
                Write-Host "  ⏳ Attempt $attempt/$maxAttempts..." -ForegroundColor Gray
            }
        }
        
        if (-not $dockerReady) {
            Write-Host "`n  ✗ Docker Desktop did not start in time" -ForegroundColor Red
            Write-Host "  Please start Docker Desktop manually and wait for it to be ready" -ForegroundColor Yellow
            Write-Host "  Then run this script again" -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "`n  ✗ Docker Desktop not found at: $dockerPath" -ForegroundColor Red
        Write-Host "  Please install Docker Desktop from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
        exit 1
    }
}

# Step 2: Show Docker version
Write-Host "`n[2/6] Docker Information..." -ForegroundColor Yellow
$dockerVersion = docker --version
Write-Host "  Version: $dockerVersion" -ForegroundColor White

# Step 3: Choose build method
Write-Host "`n[3/6] Choose build method..." -ForegroundColor Yellow
Write-Host "  1. Skip build - Use official image (5 minutes) ⭐ RECOMMENDED" -ForegroundColor Cyan
Write-Host "  2. Build from Windows-compatible Dockerfile (20 minutes)" -ForegroundColor White

$choice = Read-Host "`n  Enter your choice (1 or 2)"

if ($choice -eq "1") {
    # Skip build method
    Write-Host "`n[4/6] Pulling official Langflow image..." -ForegroundColor Yellow
    docker pull langflowai/langflow:latest
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ✗ Failed to pull official image" -ForegroundColor Red
        exit 1
    }
    Write-Host "  ✓ Official image pulled successfully" -ForegroundColor Green
    
    Write-Host "`n[5/6] Tagging image as cera123/langflow:latest..." -ForegroundColor Yellow
    docker tag langflowai/langflow:latest cera123/langflow:latest
    Write-Host "  ✓ Image tagged successfully" -ForegroundColor Green
    
} elseif ($choice -eq "2") {
    # Build method
    Write-Host "`n[4/6] Building Docker image..." -ForegroundColor Yellow
    Write-Host "  This will take 15-20 minutes. Please be patient..." -ForegroundColor Cyan
    Write-Host "  Using: docker/build_windows_compatible.Dockerfile" -ForegroundColor White
    
    docker build -f docker/build_windows_compatible.Dockerfile -t cera123/langflow:latest .
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n  ✗ Build failed" -ForegroundColor Red
        Write-Host "  Try option 1 (Skip build) instead" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "  ✓ Build completed successfully" -ForegroundColor Green
    
    Write-Host "`n[5/6] Image built..." -ForegroundColor Yellow
    
} else {
    Write-Host "  Invalid choice. Exiting." -ForegroundColor Red
    exit 1
}

# Step 6: Verify and push
Write-Host "`n[6/6] Verifying image..." -ForegroundColor Yellow
$image = docker images cera123/langflow:latest --format "{{.Repository}}:{{.Tag}}\t{{.Size}}"
Write-Host "  Image: $image" -ForegroundColor White

Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                IMAGE READY! 🎉                        ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n📦 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Login to Docker Hub:" -ForegroundColor White
Write-Host "     docker login" -ForegroundColor Yellow
Write-Host "`n  2. Push the image:" -ForegroundColor White
Write-Host "     docker push cera123/langflow:latest" -ForegroundColor Yellow

Write-Host "`n  OR run these commands now:" -ForegroundColor Cyan
$pushNow = Read-Host "  Do you want to push to Docker Hub now? (y/n)"

if ($pushNow -eq "y" -or $pushNow -eq "Y") {
    Write-Host "`n  Logging into Docker Hub..." -ForegroundColor Yellow
    docker login
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Login successful" -ForegroundColor Green
        Write-Host "`n  Pushing image..." -ForegroundColor Yellow
        docker push cera123/langflow:latest
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
            Write-Host "║              🎉 SUCCESS! 🎉                           ║" -ForegroundColor Green
            Write-Host "║   Image pushed to Docker Hub successfully!           ║" -ForegroundColor Green
            Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green
            Write-Host "`n  Your image is now available at:" -ForegroundColor Cyan
            Write-Host "  https://hub.docker.com/r/cera123/langflow" -ForegroundColor White
            Write-Host "`n  Share these files with your cloud team:" -ForegroundColor Cyan
            Write-Host "  - langflow-deployment/docker-compose.yml" -ForegroundColor White
            Write-Host "  - langflow-deployment/DOCKER_README.md" -ForegroundColor White
        } else {
            Write-Host "  ✗ Push failed" -ForegroundColor Red
        }
    } else {
        Write-Host "  ✗ Login failed" -ForegroundColor Red
    }
} else {
    Write-Host "`n  Run these commands when ready:" -ForegroundColor Cyan
    Write-Host "  docker login" -ForegroundColor Yellow
    Write-Host "  docker push cera123/langflow:latest" -ForegroundColor Yellow
}

Write-Host "`n═══════════════════════════════════════════════════════`n" -ForegroundColor Green



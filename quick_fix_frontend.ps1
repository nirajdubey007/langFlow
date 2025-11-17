# Quick Fix for Langflow Frontend Issue
# Tries simpler solutions before full rebuild

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Langflow Frontend Quick Fix" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "Checking Docker status..." -ForegroundColor Yellow
try {
    docker ps | Out-Null
    Write-Host "✓ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker is not running!" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and run this script again." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "This script will try 3 solutions:" -ForegroundColor Cyan
Write-Host "  1. Use a stable version tag (fastest)" -ForegroundColor White
Write-Host "  2. Pull latest official image" -ForegroundColor White
Write-Host "  3. Build from source (comprehensive)" -ForegroundColor White
Write-Host ""

# Solution 1: Try a stable version
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Solution 1: Use Stable Version Tag" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$tryStable = Read-Host "Try using Langflow version 1.0.19 (stable)? (Y/n)"
if ($tryStable -ne "n" -and $tryStable -ne "N") {
    Write-Host "Updating docker-compose.yml..." -ForegroundColor Yellow
    
    # Backup current docker-compose.yml
    Copy-Item "docker-compose.yml" "docker-compose.yml.backup" -Force
    Write-Host "✓ Backup created: docker-compose.yml.backup" -ForegroundColor Green
    
    # Update to use stable version
    $content = Get-Content "docker-compose.yml" -Raw
    $content = $content -replace 'build:[\s\S]*?dockerfile: Dockerfile', 'image: langflowai/langflow:1.0.19'
    $content = $content -replace 'image: langflow-custom:latest', 'image: langflowai/langflow:1.0.19'
    $content = $content -replace 'image: langflowai/langflow:latest', 'image: langflowai/langflow:1.0.19'
    Set-Content "docker-compose.yml" $content
    
    Write-Host "Stopping containers..." -ForegroundColor Yellow
    docker-compose down
    
    Write-Host "Pulling stable image..." -ForegroundColor Yellow
    docker-compose pull
    
    Write-Host "Starting containers..." -ForegroundColor Yellow
    docker-compose up -d
    
    Write-Host "Waiting for initialization..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:7860/health" -TimeoutSec 5 -UseBasicParsing -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host ""
            Write-Host "✓ SUCCESS! Langflow is working!" -ForegroundColor Green
            Write-Host "Access at: http://localhost:7860" -ForegroundColor Cyan
            Write-Host ""
            $openBrowser = Read-Host "Open in browser? (Y/n)"
            if ($openBrowser -ne "n" -and $openBrowser -ne "N") {
                Start-Process "http://localhost:7860"
            }
            Read-Host "Press Enter to exit"
            exit 0
        }
    } catch {
        Write-Host "✗ Still having issues. Trying next solution..." -ForegroundColor Yellow
        
        # Restore backup
        Copy-Item "docker-compose.yml.backup" "docker-compose.yml" -Force
    }
    Write-Host ""
}

# Solution 2: Try latest official image
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Solution 2: Pull Latest Official Image" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$tryLatest = Read-Host "Try pulling the latest official image? (Y/n)"
if ($tryLatest -ne "n" -and $tryLatest -ne "N") {
    # Restore backup if exists
    if (Test-Path "docker-compose.yml.backup") {
        Copy-Item "docker-compose.yml.backup" "docker-compose.yml" -Force
    }
    
    # Update to use latest
    $content = Get-Content "docker-compose.yml" -Raw
    $content = $content -replace 'build:[\s\S]*?dockerfile: Dockerfile', 'image: langflowai/langflow:latest'
    $content = $content -replace 'image: langflow-custom:latest', 'image: langflowai/langflow:latest'
    Set-Content "docker-compose.yml" $content
    
    Write-Host "Stopping containers..." -ForegroundColor Yellow
    docker-compose down
    
    Write-Host "Pulling latest image..." -ForegroundColor Yellow
    docker pull langflowai/langflow:latest
    
    Write-Host "Starting containers..." -ForegroundColor Yellow
    docker-compose up -d
    
    Write-Host "Waiting for initialization..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:7860/health" -TimeoutSec 5 -UseBasicParsing -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host ""
            Write-Host "✓ SUCCESS! Langflow is working!" -ForegroundColor Green
            Write-Host "Access at: http://localhost:7860" -ForegroundColor Cyan
            Write-Host ""
            $openBrowser = Read-Host "Open in browser? (Y/n)"
            if ($openBrowser -ne "n" -and $openBrowser -ne "N") {
                Start-Process "http://localhost:7860"
            }
            Read-Host "Press Enter to exit"
            exit 0
        }
    } catch {
        Write-Host "✗ Still having issues. Trying final solution..." -ForegroundColor Yellow
        
        # Restore backup
        if (Test-Path "docker-compose.yml.backup") {
            Copy-Item "docker-compose.yml.backup" "docker-compose.yml" -Force
        }
    }
    Write-Host ""
}

# Solution 3: Build from source
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Solution 3: Build from Source" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The quick fixes didn't work. Building from source is the most reliable solution." -ForegroundColor Yellow
Write-Host "This will take 10-15 minutes but ensures frontend is included." -ForegroundColor Yellow
Write-Host ""

$buildFromSource = Read-Host "Build Langflow from source? (Y/n)"
if ($buildFromSource -ne "n" -and $buildFromSource -ne "N") {
    Write-Host ""
    Write-Host "Starting full rebuild..." -ForegroundColor Yellow
    
    # Restore the build configuration
    if (Test-Path "docker-compose.yml.backup") {
        Copy-Item "docker-compose.yml.backup" "docker-compose.yml" -Force
    }
    
    # Run the full rebuild script
    if (Test-Path "rebuild_langflow.ps1") {
        & .\rebuild_langflow.ps1
    } else {
        Write-Host "rebuild_langflow.ps1 not found. Running manual rebuild..." -ForegroundColor Yellow
        docker-compose down -v
        docker-compose build --no-cache
        docker-compose up -d
        Write-Host ""
        Write-Host "Build complete! Check status at: http://localhost:7860" -ForegroundColor Cyan
        Write-Host "View logs with: docker logs langflow-app -f" -ForegroundColor White
    }
} else {
    Write-Host ""
    Write-Host "No solution applied." -ForegroundColor Yellow
    Write-Host "You can manually run: .\rebuild_langflow.ps1" -ForegroundColor White
}

Write-Host ""
Read-Host "Press Enter to exit"


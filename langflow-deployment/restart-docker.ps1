# Restart Docker Desktop and verify it's working
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Docker Desktop Restart Helper" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Try to stop Docker Desktop
Write-Host "Step 1: Stopping Docker Desktop..." -ForegroundColor Yellow
try {
    Stop-Process -Name "Docker Desktop" -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Docker Desktop stopped" -ForegroundColor Green
} catch {
    Write-Host "[INFO] Docker Desktop was not running" -ForegroundColor Gray
}

# Wait a bit
Write-Host ""
Write-Host "Waiting 5 seconds..." -ForegroundColor Gray
Start-Sleep -Seconds 5

# Step 2: Start Docker Desktop
Write-Host ""
Write-Host "Step 2: Starting Docker Desktop..." -ForegroundColor Yellow
try {
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    Write-Host "[OK] Docker Desktop started" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Could not auto-start Docker Desktop" -ForegroundColor Yellow
    Write-Host "Please start Docker Desktop manually from Start Menu" -ForegroundColor Yellow
}

# Step 3: Wait for Docker to be ready
Write-Host ""
Write-Host "Step 3: Waiting for Docker Engine to be ready..." -ForegroundColor Yellow
Write-Host "(This may take 30-60 seconds)" -ForegroundColor Gray
Write-Host ""

$maxAttempts = 30
$attempt = 0
$dockerReady = $false

while ($attempt -lt $maxAttempts) {
    $attempt++
    Write-Host "  Attempt $attempt/$maxAttempts..." -NoNewline
    
    try {
        docker info 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host " [OK]" -ForegroundColor Green
            $dockerReady = $true
            break
        } else {
            Write-Host " waiting..." -ForegroundColor Gray
        }
    } catch {
        Write-Host " waiting..." -ForegroundColor Gray
    }
    
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($dockerReady) {
    Write-Host "[SUCCESS] Docker is ready!" -ForegroundColor Green
    Write-Host ""
    
    # Show Docker info
    $dockerVersion = docker --version
    Write-Host "Docker Version: $dockerVersion" -ForegroundColor White
    
    Write-Host ""
    Write-Host "Next step:" -ForegroundColor Yellow
    Write-Host "  cd langflow-deployment" -ForegroundColor Cyan
    Write-Host "  .\build-and-test.ps1" -ForegroundColor Cyan
} else {
    Write-Host "[FAILED] Docker did not start properly" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please try:" -ForegroundColor Yellow
    Write-Host "1. Manually restart Docker Desktop" -ForegroundColor White
    Write-Host "2. Check Docker Desktop logs (Settings -> Troubleshoot)" -ForegroundColor White
    Write-Host "3. Restart your computer if issues persist" -ForegroundColor White
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""


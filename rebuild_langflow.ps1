# Rebuild Langflow with Frontend
# This script will rebuild Langflow from source to include the frontend

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Langflow Frontend Fix - Rebuild Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "[1/6] Checking Docker status..." -ForegroundColor Yellow
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

# Stop existing containers
Write-Host "[2/6] Stopping existing containers..." -ForegroundColor Yellow
docker-compose down -v
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Containers stopped" -ForegroundColor Green
} else {
    Write-Host "✓ No containers to stop" -ForegroundColor Green
}

Write-Host ""

# Clean up old images and build cache (optional but recommended)
Write-Host "[3/6] Cleaning up old images (optional)..." -ForegroundColor Yellow
$cleanup = Read-Host "Do you want to clean up old Docker images? This frees up space. (y/N)"
if ($cleanup -eq "y" -or $cleanup -eq "Y") {
    Write-Host "Cleaning up..." -ForegroundColor Yellow
    docker system prune -f
    Write-Host "✓ Cleanup complete" -ForegroundColor Green
} else {
    Write-Host "✓ Skipping cleanup" -ForegroundColor Green
}

Write-Host ""

# Build the new image
Write-Host "[4/6] Building Langflow with frontend (this may take 10-15 minutes)..." -ForegroundColor Yellow
Write-Host "Please be patient, this is building both frontend and backend from source..." -ForegroundColor Cyan
docker-compose build --no-cache
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Build successful!" -ForegroundColor Green
} else {
    Write-Host "✗ Build failed!" -ForegroundColor Red
    Write-Host "Check the error messages above." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

# Start the containers
Write-Host "[5/6] Starting containers..." -ForegroundColor Yellow
docker-compose up -d
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Containers started" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to start containers!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

# Wait for initialization
Write-Host "[6/6] Waiting for Langflow to initialize..." -ForegroundColor Yellow
Write-Host "This may take 1-2 minutes..." -ForegroundColor Cyan

$maxAttempts = 40
$attempt = 0
$ready = $false

while ($attempt -lt $maxAttempts -and -not $ready) {
    Start-Sleep -Seconds 3
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:7860/health" -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            $ready = $true
            Write-Host "✓ Langflow is ready!" -ForegroundColor Green
        }
    } catch {
        Write-Host "." -NoNewline -ForegroundColor Gray
    }
    $attempt++
}

Write-Host ""
Write-Host ""

if ($ready) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  SUCCESS! Langflow is running!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Access Langflow at: http://localhost:7860" -ForegroundColor Cyan
    Write-Host "Username: admin" -ForegroundColor Cyan
    Write-Host "Password: admin123" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Useful commands:" -ForegroundColor Yellow
    Write-Host "  View logs:      docker logs langflow-app -f" -ForegroundColor White
    Write-Host "  Stop:           docker-compose down" -ForegroundColor White
    Write-Host "  Restart:        docker-compose restart" -ForegroundColor White
    Write-Host "  Check status:   docker ps" -ForegroundColor White
    Write-Host ""
    
    # Ask if user wants to open browser
    $openBrowser = Read-Host "Open Langflow in browser? (Y/n)"
    if ($openBrowser -ne "n" -and $openBrowser -ne "N") {
        Start-Process "http://localhost:7860"
    }
} else {
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  Langflow is starting (may need more time)" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "The containers are running but may still be initializing." -ForegroundColor Yellow
    Write-Host "Wait another minute and try: http://localhost:7860" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Check logs with: docker logs langflow-app -f" -ForegroundColor White
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"


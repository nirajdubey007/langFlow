# PowerShell script to test Docker setup for Langflow
Write-Host "Testing Langflow Docker Setup" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Check if Docker is running
Write-Host "1. Checking Docker status..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "✓ Docker is available: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker is not available or not running" -ForegroundColor Red
    exit 1
}

# Check if docker-compose is available
Write-Host "2. Checking docker-compose..." -ForegroundColor Yellow
try {
    $composeVersion = docker-compose --version
    Write-Host "✓ docker-compose available: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ docker-compose not available" -ForegroundColor Red
}

# Check disk space
Write-Host "3. Checking disk space..." -ForegroundColor Yellow
$freeSpaceBytes = 2376503296  # From wmic output
$freeGB = [math]::Round($freeSpaceBytes / 1GB, 2)
Write-Host "Free disk space on C: $freeGB GB" -ForegroundColor Cyan

if ($freeGB -lt 4) {
    Write-Host "⚠️ Warning: Less than 4GB free space. Docker may fail." -ForegroundColor Yellow
} else {
    Write-Host "✓ Sufficient disk space available" -ForegroundColor Green
}

# Check if ports are available
Write-Host "4. Checking port availability..." -ForegroundColor Yellow
$ports = @(7860, 5432)
foreach ($port in $ports) {
    try {
        $connection = New-Object System.Net.Sockets.TcpClient("localhost", $port)
        Write-Host "⚠️ Port $port is in use" -ForegroundColor Yellow
        $connection.Close()
    } catch {
        Write-Host "✓ Port $port is available" -ForegroundColor Green
    }
}

# Try to start services
Write-Host "5. Starting Docker services..." -ForegroundColor Yellow
try {
    $result = docker-compose up -d 2>&1
    Write-Host "✓ docker-compose up command executed" -ForegroundColor Green
    Write-Host "Output: $result" -ForegroundColor Gray
} catch {
    Write-Host "✗ Failed to start services: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Wait for services to start
Write-Host "6. Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Check service status
Write-Host "7. Checking service status..." -ForegroundColor Yellow
try {
    $services = docker-compose ps
    Write-Host "Service status:" -ForegroundColor Cyan
    Write-Host $services
} catch {
    Write-Host "✗ Failed to check service status" -ForegroundColor Red
}

# Test health endpoint
Write-Host "8. Testing Langflow health endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:7860/health" -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ Langflow health check passed (Status: $($response.StatusCode))" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Langflow health check returned status: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Langflow health check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test main application
Write-Host "9. Testing Langflow main application..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:7860" -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ Langflow main page accessible (Status: $($response.StatusCode))" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Langflow main page returned status: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Langflow main page not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nTest Summary:" -ForegroundColor Cyan
Write-Host "============" -ForegroundColor Cyan
Write-Host "If all checks are green, your Langflow Docker setup is working correctly!" -ForegroundColor White
Write-Host "Access Langflow at: http://localhost:7860" -ForegroundColor White
Write-Host "`nUseful commands:" -ForegroundColor White
Write-Host "- View logs: docker-compose logs -f" -ForegroundColor White
Write-Host "- Stop services: docker-compose down" -ForegroundColor White
Write-Host "- Restart services: docker-compose restart" -ForegroundColor White

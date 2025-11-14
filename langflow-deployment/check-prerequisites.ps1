# Check Prerequisites for Docker Build
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Docker Build Prerequisites Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$allGood = $true

# Check 1: Docker installed
Write-Host "Checking Docker installation..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "[OK] Docker installed: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Docker is not installed" -ForegroundColor Red
    Write-Host "  Install from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    $allGood = $false
}

# Check 2: Docker running
Write-Host ""
Write-Host "Checking if Docker is running..." -ForegroundColor Yellow
try {
    docker info | Out-Null
    Write-Host "[OK] Docker is running" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Docker is not running" -ForegroundColor Red
    Write-Host "  Please start Docker Desktop" -ForegroundColor Yellow
    $allGood = $false
}

# Check 3: Disk space
Write-Host ""
Write-Host "Checking available disk space..." -ForegroundColor Yellow
$drive = (Get-Location).Drive.Name
$disk = Get-PSDrive -Name $drive
$freeSpaceGB = [math]::Round($disk.Free / 1GB, 2)
if ($freeSpaceGB -gt 10) {
    Write-Host "[OK] Available space: $freeSpaceGB GB" -ForegroundColor Green
} else {
    Write-Host "[WARN] Low disk space: $freeSpaceGB GB (recommend 10+ GB)" -ForegroundColor Yellow
    Write-Host "  Consider running: docker system prune -a" -ForegroundColor Yellow
}

# Check 4: Dockerfile exists
Write-Host ""
Write-Host "Checking Dockerfile..." -ForegroundColor Yellow
if (Test-Path "build_and_push_fixed.Dockerfile") {
    Write-Host "[OK] Dockerfile found" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Dockerfile not found" -ForegroundColor Red
    $allGood = $false
}

# Check 5: Project structure
Write-Host ""
Write-Host "Checking project structure..." -ForegroundColor Yellow
$requiredPaths = @(
    "..\pyproject.toml",
    "..\uv.lock",
    "..\src\backend\base",
    "..\src\frontend"
)
$missingPaths = @()
foreach ($path in $requiredPaths) {
    if (-not (Test-Path $path)) {
        $missingPaths += $path
    }
}
if ($missingPaths.Count -eq 0) {
    Write-Host "[OK] All required files present" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Missing files:" -ForegroundColor Red
    foreach ($path in $missingPaths) {
        Write-Host "  - $path" -ForegroundColor Red
    }
    $allGood = $false
}

# Check 6: Docker Hub login (optional)
Write-Host ""
Write-Host "Checking Docker Hub authentication..." -ForegroundColor Yellow
$loginCheck = docker info 2>&1 | Select-String "Username"
if ($loginCheck) {
    $username = ($loginCheck -split ':')[1].Trim()
    Write-Host "[OK] Logged in as: $username" -ForegroundColor Green
} else {
    Write-Host "[WARN] Not logged in to Docker Hub" -ForegroundColor Yellow
    Write-Host "  Login with: docker login" -ForegroundColor Yellow
    Write-Host "  (Only needed before pushing to Docker Hub)" -ForegroundColor Gray
}

# Check 7: Memory allocated to Docker
Write-Host ""
Write-Host "Checking Docker resources..." -ForegroundColor Yellow
try {
    $dockerInfo = docker info 2>&1 | Out-String
    if ($dockerInfo -match "Total Memory: ([0-9.]+)GiB") {
        $memory = [math]::Round([double]$Matches[1], 2)
        if ($memory -ge 4) {
            Write-Host "[OK] Docker Memory: $memory GB" -ForegroundColor Green
        } else {
            Write-Host "[WARN] Docker Memory: $memory GB (recommend 4+ GB)" -ForegroundColor Yellow
            Write-Host "  Increase in Docker Desktop -> Settings -> Resources" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[INFO] Could not detect Docker memory allocation" -ForegroundColor Gray
    }
} catch {
    Write-Host "[INFO] Could not check Docker resources" -ForegroundColor Gray
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($allGood) {
    Write-Host "[SUCCESS] All checks passed! Ready to build." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next step:" -ForegroundColor Yellow
    Write-Host "  .\build-and-test.ps1" -ForegroundColor Cyan
} else {
    Write-Host "[FAILED] Some checks failed" -ForegroundColor Red
    Write-Host "Please fix the issues above before building." -ForegroundColor Yellow
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

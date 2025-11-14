# Comprehensive Disk Space Cleanup Script
# Cleans Docker cache, temp files, and other space hogs

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Disk Space Cleanup Utility" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check initial disk space
$drive = "C"
$disk = Get-PSDrive -Name $drive
$initialFree = [math]::Round($disk.Free / 1GB, 2)
Write-Host "Initial free space: $initialFree GB" -ForegroundColor Yellow
Write-Host ""

$totalFreed = 0

# 1. Clean Docker
Write-Host "1. Cleaning Docker..." -ForegroundColor Yellow
try {
    docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   - Removing stopped containers..." -ForegroundColor Gray
        docker container prune -f 2>&1 | Out-Null
        
        Write-Host "   - Removing dangling images..." -ForegroundColor Gray
        docker image prune -f 2>&1 | Out-Null
        
        Write-Host "   - Removing build cache..." -ForegroundColor Gray
        $dockerClean = docker builder prune -af 2>&1 | Out-String
        if ($dockerClean -match "Total:\s+([0-9.]+)([MG]B)") {
            $size = [double]$Matches[1]
            $unit = $Matches[2]
            if ($unit -eq "GB") {
                $sizeGB = $size
            } else {
                $sizeGB = $size / 1024
            }
            Write-Host "   [OK] Freed $size $unit from Docker" -ForegroundColor Green
            $totalFreed += $sizeGB
        }
        
        Write-Host "   - Removing unused volumes..." -ForegroundColor Gray
        docker volume prune -f 2>&1 | Out-Null
        
        Write-Host "   - Removing unused networks..." -ForegroundColor Gray
        docker network prune -f 2>&1 | Out-Null
        
        Write-Host "   [OK] Docker cleanup complete" -ForegroundColor Green
    } else {
        Write-Host "   [SKIP] Docker not running" -ForegroundColor Gray
    }
} catch {
    Write-Host "   [SKIP] Docker not available" -ForegroundColor Gray
}

# 2. Clean Windows Temp
Write-Host ""
Write-Host "2. Cleaning Windows Temp folders..." -ForegroundColor Yellow
try {
    Write-Host "   - Cleaning user temp..." -ForegroundColor Gray
    $tempFiles = Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue
    $tempSize = ($tempFiles | Measure-Object -Property Length -Sum).Sum / 1GB
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "   [OK] Cleaned ~$([math]::Round($tempSize, 2)) GB" -ForegroundColor Green
    $totalFreed += $tempSize
} catch {
    Write-Host "   [WARN] Some temp files in use" -ForegroundColor Yellow
}

try {
    Write-Host "   - Cleaning Windows temp..." -ForegroundColor Gray
    $winTempFiles = Get-ChildItem -Path "C:\Windows\Temp" -Recurse -Force -ErrorAction SilentlyContinue
    $winTempSize = ($winTempFiles | Measure-Object -Property Length -Sum).Sum / 1GB
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "   [OK] Cleaned ~$([math]::Round($winTempSize, 2)) GB" -ForegroundColor Green
    $totalFreed += $winTempSize
} catch {
    Write-Host "   [INFO] Need admin rights for Windows temp" -ForegroundColor Gray
}

# 3. Clean PowerShell cache
Write-Host ""
Write-Host "3. Cleaning PowerShell cache..." -ForegroundColor Yellow
try {
    Write-Host "   - Cleaning module cache..." -ForegroundColor Gray
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\ModuleAnalysisCache" -Force -ErrorAction SilentlyContinue
    Write-Host "   [OK] PowerShell cache cleaned" -ForegroundColor Green
} catch {
    Write-Host "   [SKIP] No cache to clean" -ForegroundColor Gray
}

# 4. Clean npm cache
Write-Host ""
Write-Host "4. Cleaning npm cache..." -ForegroundColor Yellow
try {
    npm cache clean --force 2>&1 | Out-Null
    Write-Host "   [OK] npm cache cleaned" -ForegroundColor Green
} catch {
    Write-Host "   [SKIP] npm not available" -ForegroundColor Gray
}

# 5. Clean pip cache
Write-Host ""
Write-Host "5. Cleaning pip cache..." -ForegroundColor Yellow
try {
    pip cache purge 2>&1 | Out-Null
    Write-Host "   [OK] pip cache cleaned" -ForegroundColor Green
} catch {
    Write-Host "   [SKIP] pip not available" -ForegroundColor Gray
}

# 6. Clean browser caches (Chrome, Edge)
Write-Host ""
Write-Host "6. Cleaning browser caches..." -ForegroundColor Yellow
$browserCaches = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache"
)

foreach ($cache in $browserCaches) {
    if (Test-Path $cache) {
        try {
            Write-Host "   - Cleaning $(Split-Path (Split-Path $cache -Parent) -Leaf)..." -ForegroundColor Gray
            Remove-Item -Path "$cache\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "   [OK] Cleaned" -ForegroundColor Green
        } catch {
            Write-Host "   [SKIP] In use" -ForegroundColor Gray
        }
    }
}

# 7. Empty Recycle Bin
Write-Host ""
Write-Host "7. Emptying Recycle Bin..." -ForegroundColor Yellow
try {
    Clear-RecycleBin -Force -ErrorAction Stop 2>&1 | Out-Null
    Write-Host "   [OK] Recycle Bin emptied" -ForegroundColor Green
} catch {
    Write-Host "   [SKIP] Recycle Bin already empty or access denied" -ForegroundColor Gray
}

# 8. Check final disk space
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cleanup Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$disk = Get-PSDrive -Name $drive
$finalFree = [math]::Round($disk.Free / 1GB, 2)
$actualFreed = $finalFree - $initialFree

Write-Host ""
Write-Host "Before: $initialFree GB free" -ForegroundColor White
Write-Host "After:  $finalFree GB free" -ForegroundColor White
Write-Host "Freed:  $([math]::Round($actualFreed, 2)) GB" -ForegroundColor Green
Write-Host ""

if ($actualFreed -gt 1) {
    Write-Host "[SUCCESS] Freed $([math]::Round($actualFreed, 2)) GB!" -ForegroundColor Green
} elseif ($actualFreed -gt 0) {
    Write-Host "[OK] Freed $([math]::Round($actualFreed * 1024, 0)) MB" -ForegroundColor Green
} else {
    Write-Host "[INFO] Minimal space freed (caches may be in use)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Additional Cleanup Options:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Run Windows Disk Cleanup for more space:" -ForegroundColor White
Write-Host "  cleanmgr.exe /d C:" -ForegroundColor Cyan
Write-Host ""
Write-Host "Or run as admin for deep clean:" -ForegroundColor White
Write-Host "  cleanmgr.exe /d C: /verylowdisk" -ForegroundColor Cyan
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""


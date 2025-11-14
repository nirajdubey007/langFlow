# Cleanup test containers and images
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cleanup Test Containers and Images" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Stop and remove test container
Write-Host "Stopping test container..." -ForegroundColor Yellow
docker stop langflow-test 2>$null
docker rm langflow-test 2>$null
Write-Host "✓ Test container removed" -ForegroundColor Green

# Optional: Remove test images (uncomment if needed)
# Write-Host ""
# Write-Host "Removing test images..." -ForegroundColor Yellow
# docker rmi cera123/langflow:test-local 2>$null
# Write-Host "✓ Test images removed" -ForegroundColor Green

Write-Host ""
Write-Host "Cleanup complete!" -ForegroundColor Green


#!/bin/bash

echo "Testing Langflow Docker Setup"
echo "=============================="

# Check if Docker is running
echo "1. Checking Docker status..."
if docker --version >/dev/null 2>&1; then
    echo "✓ Docker is available: $(docker --version)"
else
    echo "✗ Docker is not available or not running"
    exit 1
fi

# Check if docker-compose is available
echo "2. Checking docker-compose..."
if docker-compose --version >/dev/null 2>&1; then
    echo "✓ docker-compose available: $(docker-compose --version)"
else
    echo "✗ docker-compose not available"
fi

# Check disk space
echo "3. Checking disk space..."
if command -v df >/dev/null 2>&1; then
    FREE_SPACE=$(df / | tail -1 | awk '{print $4}')
    FREE_GB=$((FREE_SPACE / 1024 / 1024))
    echo "Free disk space: ${FREE_GB} GB"

    if [ $FREE_GB -lt 4 ]; then
        echo "⚠️ Warning: Less than 4GB free space. Docker may fail."
    else
        echo "✓ Sufficient disk space available"
    fi
else
    echo "⚠️ Cannot check disk space"
fi

# Check if ports are available
echo "4. Checking port availability..."
PORTS=(7860 5432)
for port in "${PORTS[@]}"; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "⚠️ Port $port is in use"
    else
        echo "✓ Port $port is available"
    fi
done

# Try to start services
echo "5. Starting Docker services..."
if docker-compose up -d; then
    echo "✓ docker-compose up command executed"
else
    echo "✗ Failed to start services"
    exit 1
fi

# Wait for services to start
echo "6. Waiting for services to start..."
sleep 10

# Check service status
echo "7. Checking service status..."
if docker-compose ps; then
    echo "✓ Service status checked"
else
    echo "✗ Failed to check service status"
fi

# Test health endpoint
echo "8. Testing Langflow health endpoint..."
if curl -f http://localhost:7860/health >/dev/null 2>&1; then
    echo "✓ Langflow health check passed"
else
    echo "✗ Langflow health check failed"
fi

# Test main application
echo "9. Testing Langflow main application..."
if curl -f http://localhost:7860 >/dev/null 2>&1; then
    echo "✓ Langflow main page accessible"
else
    echo "✗ Langflow main page not accessible"
fi

echo ""
echo "Test Summary:"
echo "============="
echo "If all checks are green, your Langflow Docker setup is working correctly!"
echo "Access Langflow at: http://localhost:7860"
echo ""
echo "Useful commands:"
echo "- View logs: docker-compose logs -f"
echo "- Stop services: docker-compose down"
echo "- Restart services: docker-compose restart"

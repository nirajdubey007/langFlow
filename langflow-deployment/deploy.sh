#!/bin/bash
# Deploy Langflow using Docker Compose (macOS/Linux)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================"
echo "Deploy Langflow with Docker Compose"
echo "========================================"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "[FAIL] Docker is not running. Please start Docker Desktop."
    exit 1
fi

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo "[FAIL] docker-compose.yml not found in $SCRIPT_DIR"
    exit 1
fi

# Stop existing containers
echo "Stopping existing containers..."
docker-compose down 2>/dev/null || true

# Pull latest images (if using remote images)
echo ""
echo "Pulling latest images..."
docker-compose pull || echo "Note: Some images may be built locally"

# Start services
echo ""
echo "Starting services..."
docker-compose up -d

# Wait for services to be healthy
echo ""
echo "Waiting for services to start..."
sleep 10

# Check status
echo ""
echo "========================================"
echo "Deployment Status"
echo "========================================"
docker-compose ps

echo ""
echo "========================================"
echo "Service URLs"
echo "========================================"
echo "Langflow:  http://localhost:7860"
echo "PostgreSQL: localhost:5432"
echo ""
echo "Default Admin Credentials:"
echo "  Username: admin"
echo "  Password: admin123"
echo ""
echo "Useful Commands:"
echo "  View logs:        docker-compose logs -f"
echo "  Stop services:    docker-compose down"
echo "  Restart services:  docker-compose restart"
echo "  View status:       docker-compose ps"


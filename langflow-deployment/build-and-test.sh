#!/bin/bash
# Build and Test Langflow Docker Image (macOS/Linux)
# This script builds the Docker image with your customizations and tests it locally

set -e

echo "========================================"
echo "Langflow Docker Build and Test Script"
echo "========================================"
echo ""

# Configuration
DOCKER_USERNAME="${DOCKER_USERNAME:-nirajdubey007}"
IMAGE_NAME="langflow"
TAG="latest"
FULL_IMAGE_NAME="${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"
TEST_TAG="test-local"
TEST_IMAGE_NAME="${DOCKER_USERNAME}/${IMAGE_NAME}:${TEST_TAG}"

# Get project root (parent of langflow-deployment)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check if Docker is running
echo "Checking Docker status..."
if ! docker info > /dev/null 2>&1; then
    echo "[FAIL] Docker is not running. Please start Docker Desktop."
    exit 1
fi
echo "[OK] Docker is running"
echo ""

# Navigate to project root
cd "$PROJECT_ROOT"
echo "[OK] Working directory: $PROJECT_ROOT"
echo ""

# Build the Docker image
echo "========================================"
echo "Building Docker Image..."
echo "========================================"
echo "Image: $TEST_IMAGE_NAME"
echo "This will build with your customizations (Automate branding, dark theme, etc.)"
echo ""

start_time=$(date +%s)

# Use the main Dockerfile (which includes frontend build)
docker build \
    -f Dockerfile \
    -t "$TEST_IMAGE_NAME" \
    --progress=plain \
    .

if [ $? -eq 0 ]; then
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    minutes=$((duration / 60))
    seconds=$((duration % 60))
    echo ""
    echo "[SUCCESS] Build completed successfully in ${minutes}m ${seconds}s"
else
    echo ""
    echo "[FAIL] Build failed!"
    exit 1
fi

echo ""
echo "========================================"
echo "Docker Image Details"
echo "========================================"
docker images "$TEST_IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

echo ""
echo "========================================"
echo "Starting Test Container..."
echo "========================================"

# Stop any existing test container
docker rm -f langflow-test 2>/dev/null || true

# Run the container
echo "Starting container on http://localhost:7860"
docker run -d \
    --name langflow-test \
    -p 7860:7860 \
    -e LANGFLOW_LOG_LEVEL=INFO \
    -e LANGFLOW_AUTO_LOGIN=true \
    "$TEST_IMAGE_NAME"

if [ $? -eq 0 ]; then
    echo "[OK] Container started successfully"
    echo ""
    echo "Waiting 10 seconds for container to initialize..."
    sleep 10
    echo ""
    echo "Container Logs (last 20 lines):"
    docker logs --tail 20 langflow-test
    
    echo ""
    echo "========================================"
    echo "Test Results"
    echo "========================================"
    container_id=$(docker ps -q -f name=langflow-test)
    echo "[OK] Container ID: $container_id"
    echo "[OK] Access Langflow at: http://localhost:7860"
    echo ""
    echo "Useful Commands:"
    echo "  View logs:        docker logs -f langflow-test"
    echo "  Stop container:   docker stop langflow-test"
    echo "  Remove container: docker rm -f langflow-test"
    echo "  Push to hub:      ./push-to-hub.sh"
    echo ""
    echo "To test the application, open: http://localhost:7860"
    echo ""
    echo "Your customizations should be visible:"
    echo "  - Dark theme (#01051f background)"
    echo "  - 'Automate' branding"
    echo "  - 'Login' instead of 'Sign in to Langflow'"
    echo "  - No Langflow logos"
else
    echo "[FAIL] Failed to start container"
    exit 1
fi


#!/bin/bash
# Push Langflow Docker Image to Docker Hub (macOS/Linux)

set -e

echo "========================================"
echo "Push Langflow Image to Docker Hub"
echo "========================================"
echo ""

# Configuration
DOCKER_USERNAME="${DOCKER_USERNAME:-nirajdubey007}"
IMAGE_NAME="langflow"
TEST_TAG="test-local"
LATEST_TAG="latest"
TEST_IMAGE="${DOCKER_USERNAME}/${IMAGE_NAME}:${TEST_TAG}"
LATEST_IMAGE="${DOCKER_USERNAME}/${IMAGE_NAME}:${LATEST_TAG}"

# Check if test image exists
if ! docker images "$TEST_IMAGE" | grep -q "$IMAGE_NAME"; then
    echo "[ERROR] Test image not found: $TEST_IMAGE"
    echo "Please run ./build-and-test.sh first"
    exit 1
fi

# Check if logged in to Docker Hub
echo "Checking Docker Hub login status..."
if ! docker info | grep -q "Username"; then
    echo "Please login to Docker Hub:"
    docker login
fi

# Tag the test image as latest
echo ""
echo "Tagging image as latest..."
docker tag "$TEST_IMAGE" "$LATEST_IMAGE"

# Push both tags
echo ""
echo "Pushing to Docker Hub..."
echo "Pushing $TEST_IMAGE..."
docker push "$TEST_IMAGE"

echo ""
echo "Pushing $LATEST_IMAGE..."
docker push "$LATEST_IMAGE"

echo ""
echo "========================================"
echo "Success!"
echo "========================================"
echo "Your image is now available at:"
echo "  - $TEST_IMAGE"
echo "  - $LATEST_IMAGE"
echo ""
echo "Update docker-compose.yml to use: $LATEST_IMAGE"


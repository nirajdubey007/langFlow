#!/bin/bash
# Test Docker Hub Token Locally

echo "========================================"
echo "Docker Hub Token Tester"
echo "========================================"
echo ""

# Check if token is provided
if [ -z "$1" ]; then
    echo "Usage: ./test-docker-token.sh <your-docker-hub-token>"
    echo ""
    echo "Example:"
    echo "  ./test-docker-token.sh dckr_pat_xxxxxxxxxxxxxxxxxxxxx"
    exit 1
fi

TOKEN=$1
USERNAME=${2:-nirajdubey007}

echo "Testing Docker Hub authentication..."
echo "Username: $USERNAME"
echo ""

# Test login
echo "$TOKEN" | docker login -u "$USERNAME" --password-stdin docker.io

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SUCCESS! Token is valid and working!"
    echo ""
    echo "Next steps:"
    echo "1. Copy this token"
    echo "2. Go to: https://github.com/nirajdubey007/langFlow/settings/secrets/actions"
    echo "3. Add/Update secret: DOCKERHUB_TOKEN"
    echo "4. Re-run the GitHub Actions workflow"
else
    echo ""
    echo "❌ FAILED! Token is invalid or incorrect"
    echo ""
    echo "Possible issues:"
    echo "- Token is incorrect (check for typos)"
    echo "- Token doesn't have Read, Write, Delete permissions"
    echo "- Username doesn't match the token"
    echo "- Token was revoked"
    echo ""
    echo "Solution:"
    echo "1. Go to: https://hub.docker.com/settings/security"
    echo "2. Delete old token"
    echo "3. Create new token with Read, Write, Delete permissions"
    echo "4. Test again with new token"
fi


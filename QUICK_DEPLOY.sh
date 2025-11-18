#!/bin/bash

# Langflow Quick Deployment Script for Server
# This script helps you quickly deploy Langflow on your server

set -e

echo "🚀 Langflow Server Deployment Script"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    print_warning "Please don't run as root. Run as a regular user with sudo privileges."
    exit 1
fi

# Step 1: Check Docker installation
echo ""
echo "Step 1: Checking Docker installation..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    print_success "Docker is installed: $DOCKER_VERSION"
else
    print_warning "Docker is not installed. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    print_success "Docker installed successfully"
    print_warning "You need to logout and login again for group changes to take effect"
    exit 0
fi

# Check Docker Compose
if docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version)
    print_success "Docker Compose is installed: $COMPOSE_VERSION"
else
    print_error "Docker Compose is not installed"
    echo "Installing Docker Compose plugin..."
    sudo apt update
    sudo apt install docker-compose-plugin -y
    print_success "Docker Compose installed"
fi

# Step 2: Create deployment directory
echo ""
echo "Step 2: Setting up deployment directory..."
DEPLOY_DIR="$HOME/langflow-deployment"

if [ ! -d "$DEPLOY_DIR" ]; then
    mkdir -p "$DEPLOY_DIR/docker"
    print_success "Created directory: $DEPLOY_DIR"
else
    print_warning "Directory already exists: $DEPLOY_DIR"
fi

cd "$DEPLOY_DIR"

# Step 3: Check if configuration files exist
echo ""
echo "Step 3: Checking configuration files..."

FILES_MISSING=false

if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found"
    FILES_MISSING=true
fi

if [ ! -f ".env" ]; then
    print_error ".env file not found"
    FILES_MISSING=true
fi

if [ ! -f "docker/init.sql" ]; then
    print_error "docker/init.sql not found"
    FILES_MISSING=true
fi

if [ "$FILES_MISSING" = true ]; then
    echo ""
    print_warning "Missing required files. Please copy these files from your local machine:"
    echo "  1. docker-compose.production.yml → $DEPLOY_DIR/docker-compose.yml"
    echo "  2. env.production.template → $DEPLOY_DIR/.env (and configure it)"
    echo "  3. docker/init.sql → $DEPLOY_DIR/docker/init.sql"
    echo ""
    echo "From your LOCAL machine, run:"
    echo "  scp docker-compose.production.yml user@your-server:$DEPLOY_DIR/docker-compose.yml"
    echo "  scp env.production.template user@your-server:$DEPLOY_DIR/.env"
    echo "  scp docker/init.sql user@your-server:$DEPLOY_DIR/docker/init.sql"
    exit 1
fi

print_success "All configuration files present"

# Step 4: Check environment variables
echo ""
echo "Step 4: Checking environment variables..."

if grep -q "CHANGE_THIS" .env; then
    print_error "Environment variables not configured!"
    print_warning "Please edit .env file and change default values:"
    echo "  nano .env"
    echo ""
    echo "Make sure to change:"
    echo "  - POSTGRES_PASSWORD"
    echo "  - LANGFLOW_SUPERUSER_PASSWORD"
    echo "  - LANGFLOW_SECRET_KEY (generate with: openssl rand -hex 32)"
    echo "  - LANGFLOW_CORS_ORIGINS (your domain)"
    exit 1
fi

print_success "Environment variables configured"

# Step 5: Check if services are already running
echo ""
echo "Step 5: Checking existing services..."

if docker compose ps | grep -q "Up"; then
    print_warning "Services are already running"
    read -p "Do you want to restart them? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker compose down
        print_success "Stopped existing services"
    else
        print_info "Keeping existing services running"
        exit 0
    fi
fi

# Step 6: Pull images
echo ""
echo "Step 6: Pulling Docker images..."
docker compose pull
print_success "Docker images pulled"

# Step 7: Start services
echo ""
echo "Step 7: Starting services..."
docker compose up -d
print_success "Services started"

# Step 8: Wait for health check
echo ""
echo "Step 8: Waiting for services to be healthy..."
sleep 10

ATTEMPTS=0
MAX_ATTEMPTS=30

while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    if docker compose ps | grep -q "healthy"; then
        print_success "Services are healthy!"
        break
    fi
    echo -n "."
    sleep 2
    ATTEMPTS=$((ATTEMPTS + 1))
done

if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
    print_error "Services did not become healthy in time"
    echo ""
    echo "Check logs with: docker compose logs"
    exit 1
fi

# Step 9: Display status
echo ""
echo "Step 9: Deployment Status"
echo "========================="
docker compose ps

# Step 10: Test connection
echo ""
echo "Step 10: Testing connection..."
sleep 5

if curl -s http://localhost:7860/health > /dev/null; then
    print_success "Langflow is responding!"
else
    print_warning "Langflow is not responding yet, give it more time"
fi

# Final message
echo ""
echo "======================================"
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo "======================================"
echo ""
echo "Your Langflow is running at:"
echo "  Local: http://localhost:7860"
echo ""
echo "Next steps:"
echo "  1. Configure Nginx reverse proxy (see DEPLOYMENT_GUIDE.md)"
echo "  2. Setup SSL certificate with certbot"
echo "  3. Configure your domain's DNS"
echo "  4. Setup firewall rules"
echo ""
echo "Useful commands:"
echo "  View logs:     docker compose logs -f"
echo "  Stop services: docker compose stop"
echo "  Start services: docker compose start"
echo "  Restart:       docker compose restart"
echo "  Status:        docker compose ps"
echo ""
echo "For detailed instructions, see: DEPLOYMENT_GUIDE.md"
echo ""


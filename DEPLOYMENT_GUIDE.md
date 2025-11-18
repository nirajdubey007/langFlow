# Langflow Server Deployment Guide

This guide will help you deploy Langflow on your production server with PostgreSQL.

## 📋 Prerequisites

- A Linux server (Ubuntu 20.04+ or similar)
- Root or sudo access
- Domain name pointed to your server (optional, for SSL)
- Minimum 2GB RAM, 2 CPU cores, 20GB disk space

## 🚀 Quick Start

### Step 1: Install Docker and Docker Compose

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group (logout/login required)
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose-plugin -y

# Verify installation
docker --version
docker compose version
```

### Step 2: Create Deployment Directory

```bash
# Create directory for Langflow
mkdir -p ~/langflow-deployment/docker
cd ~/langflow-deployment
```

### Step 3: Copy Configuration Files

Transfer these files from your local machine to the server:

```bash
# From your LOCAL machine (in the langflow directory)
scp docker-compose.production.yml user@your-server:~/langflow-deployment/docker-compose.yml
scp .env.production.example user@your-server:~/langflow-deployment/.env
scp docker/init.sql user@your-server:~/langflow-deployment/docker/init.sql

# OR manually create the files on the server using the contents below
```

**Required files:**
1. `docker-compose.yml` (from docker-compose.production.yml)
2. `.env` (from .env.production.example)
3. `docker/init.sql` (PostgreSQL initialization)

### Step 4: Configure Environment Variables

```bash
cd ~/langflow-deployment

# Edit the .env file with your production values
nano .env
```

**Important: Change these values:**

```env
# PostgreSQL - Use strong passwords!
POSTGRES_USER=langflow
POSTGRES_PASSWORD=your_strong_database_password_here

# Langflow Admin
LANGFLOW_SUPERUSER=admin
LANGFLOW_SUPERUSER_PASSWORD=your_strong_admin_password_here

# Generate secret key with: openssl rand -hex 32
LANGFLOW_SECRET_KEY=your_64_character_secret_key_here

# CORS - Update with your domain
LANGFLOW_CORS_ORIGINS=https://yourdomain.com

# Security
LANGFLOW_AUTO_LOGIN=false
DO_NOT_TRACK=true
```

**Generate a secure secret key:**
```bash
openssl rand -hex 32
```

### Step 5: Start Langflow

```bash
cd ~/langflow-deployment

# Pull latest images
docker compose pull

# Start services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f langflow
```

### Step 6: Verify Installation

```bash
# Check if services are running
docker compose ps

# Test Langflow locally
curl http://localhost:7860/health

# You should see: {"status":"ok"}
```

## 🔒 Security Setup (Recommended)

### Option A: Setup with Nginx + SSL (Recommended for Production)

#### 1. Install Nginx

```bash
sudo apt update
sudo apt install nginx -y
```

#### 2. Install Certbot for SSL

```bash
sudo apt install certbot python3-certbot-nginx -y
```

#### 3. Configure Nginx

```bash
# Copy the nginx configuration
sudo nano /etc/nginx/sites-available/langflow

# Paste the content from nginx-langflow.conf
# Update 'yourdomain.com' with your actual domain

# Create symbolic link
sudo ln -s /etc/nginx/sites-available/langflow /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

#### 4. Get SSL Certificate

```bash
# Request SSL certificate from Let's Encrypt
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Follow the prompts to configure SSL
```

#### 5. Setup Auto-Renewal

```bash
# Test renewal
sudo certbot renew --dry-run

# Certbot automatically sets up a cron job for renewal
```

**Access your Langflow at:** `https://yourdomain.com`

### Option B: Direct Access (For Testing Only)

If you're testing without a domain:

1. Update docker-compose.yml ports to `0.0.0.0:7860:7860`
2. Configure firewall to allow port 7860
3. Access via: `http://your-server-ip:7860`

⚠️ **Warning:** This is not secure for production use!

## 🔥 Firewall Configuration

### Using UFW (Ubuntu)

```bash
# Enable firewall
sudo ufw enable

# Allow SSH (important - don't lock yourself out!)
sudo ufw allow 22/tcp

# If using Nginx
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS

# If direct access (not recommended)
sudo ufw allow 7860/tcp

# Check status
sudo ufw status
```

### Using firewalld (CentOS/RHEL)

```bash
# Enable firewall
sudo systemctl start firewalld
sudo systemctl enable firewalld

# Allow services
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-service=ssh

# Reload
sudo firewall-cmd --reload
```

## 📊 Monitoring & Management

### View Logs

```bash
# All services
docker compose logs -f

# Langflow only
docker compose logs -f langflow

# PostgreSQL only
docker compose logs -f postgres

# Last 100 lines
docker compose logs --tail=100 langflow
```

### Container Management

```bash
# Stop services
docker compose stop

# Start services
docker compose start

# Restart services
docker compose restart

# Stop and remove containers (data persists in volumes)
docker compose down

# View running containers
docker compose ps

# Check resource usage
docker stats
```

### Backup Database

```bash
# Create backup
docker compose exec postgres pg_dump -U langflow langflow > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore from backup
docker compose exec -T postgres psql -U langflow langflow < backup_file.sql
```

### Update Langflow

```bash
cd ~/langflow-deployment

# Pull latest image
docker compose pull langflow

# Recreate containers
docker compose up -d

# Remove old images
docker image prune -f
```

## 🔧 Troubleshooting

### Check Container Health

```bash
docker compose ps
docker compose logs langflow --tail=50
```

### Container Won't Start

```bash
# Check for port conflicts
sudo lsof -i :7860
sudo lsof -i :5432

# Check disk space
df -h

# Check container logs
docker compose logs langflow
```

### Database Connection Issues

```bash
# Check PostgreSQL is running
docker compose ps postgres

# Test database connection
docker compose exec postgres psql -U langflow -d langflow -c "SELECT version();"

# Check environment variables
docker compose exec langflow env | grep LANGFLOW
```

### Permission Errors

```bash
# Fix volume permissions
sudo chown -R 1000:1000 volumes/
```

### Reset Everything

```bash
# Stop and remove everything (⚠️ THIS DELETES ALL DATA)
docker compose down -v

# Start fresh
docker compose up -d
```

## 🔐 Security Best Practices

1. **Strong Passwords**: Use complex passwords for database and admin accounts
2. **Secret Key**: Generate a unique secret key using `openssl rand -hex 32`
3. **Firewall**: Only allow necessary ports (80, 443, 22)
4. **SSL/TLS**: Always use HTTPS in production
5. **Auto-Login**: Disable in production (`LANGFLOW_AUTO_LOGIN=false`)
6. **CORS**: Restrict to your specific domain, not `*`
7. **Updates**: Regularly update Docker images
8. **Backups**: Schedule regular database backups
9. **Monitoring**: Set up log monitoring and alerts
10. **Non-root**: The configuration uses user 0:0, consider creating a dedicated user

## 📁 Directory Structure

```
~/langflow-deployment/
├── docker-compose.yml          # Main configuration
├── .env                        # Environment variables (keep secret!)
├── docker/
│   └── init.sql               # PostgreSQL initialization
└── nginx-langflow.conf        # Nginx configuration (optional)
```

## 📞 Support & Resources

- **Langflow GitHub**: https://github.com/langflow-ai/langflow
- **Langflow Discord**: https://discord.com/invite/EqksyE2EX9
- **Documentation**: https://docs.langflow.org/

## ✅ Post-Deployment Checklist

- [ ] Docker and Docker Compose installed
- [ ] Configuration files copied to server
- [ ] Environment variables configured with strong passwords
- [ ] Secret key generated and set
- [ ] Services started successfully
- [ ] Health check passed
- [ ] Nginx installed and configured (if using)
- [ ] SSL certificate obtained and installed
- [ ] Firewall configured
- [ ] Domain DNS configured
- [ ] Can access Langflow via HTTPS
- [ ] Admin login works
- [ ] Database backup strategy in place
- [ ] Monitoring/logging configured

## 🎉 You're Done!

Your Langflow instance should now be running on your server!

Access it at: **https://yourdomain.com** (or your configured domain)

Login with your configured admin credentials.


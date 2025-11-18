# 🚀 Langflow Server Setup - Quick Summary

## 📦 Files You Need to Transfer to Your Server

I've created the following files for your server deployment:

### Required Files:
1. **`docker-compose.production.yml`** - Production Docker Compose configuration
2. **`env.production.template`** - Environment variables template
3. **`docker/init.sql`** - PostgreSQL initialization script
4. **`DEPLOYMENT_GUIDE.md`** - Complete deployment guide
5. **`nginx-langflow.conf`** - Nginx reverse proxy configuration
6. **`QUICK_DEPLOY.sh`** - Automated deployment script

---

## ⚡ Quick Setup (3 Methods)

### Method 1: Automated Script (Easiest)

```bash
# On your LOCAL machine
scp docker-compose.production.yml user@your-server:~/langflow-deployment/docker-compose.yml
scp env.production.template user@your-server:~/langflow-deployment/.env
scp -r docker user@your-server:~/langflow-deployment/
scp QUICK_DEPLOY.sh user@your-server:~/langflow-deployment/

# On your SERVER
cd ~/langflow-deployment
nano .env  # Configure your passwords and settings
chmod +x QUICK_DEPLOY.sh
./QUICK_DEPLOY.sh
```

### Method 2: Manual Setup

```bash
# 1. On your SERVER, create directory
ssh user@your-server
mkdir -p ~/langflow-deployment/docker
cd ~/langflow-deployment

# 2. Create docker-compose.yml
nano docker-compose.yml
# Copy content from docker-compose.production.yml

# 3. Create .env file
nano .env
# Copy content from env.production.template and configure

# 4. Create PostgreSQL init script
nano docker/init.sql
# Copy content from docker/init.sql

# 5. Start services
docker compose pull
docker compose up -d

# 6. Check status
docker compose ps
docker compose logs -f langflow
```

### Method 3: SCP Transfer (Recommended)

```bash
# From your LOCAL machine (in the langflow directory)
cd /Users/dev/Desktop/langflow/langFlow

# Transfer files
scp docker-compose.production.yml user@your-server:~/langflow-deployment/docker-compose.yml
scp env.production.template user@your-server:~/langflow-deployment/.env
scp docker/init.sql user@your-server:~/langflow-deployment/docker/init.sql
scp DEPLOYMENT_GUIDE.md user@your-server:~/langflow-deployment/
scp nginx-langflow.conf user@your-server:~/langflow-deployment/

# Then on your SERVER
ssh user@your-server
cd ~/langflow-deployment

# Configure environment
nano .env
# Change ALL passwords and settings!

# Start services
docker compose pull
docker compose up -d
```

---

## ⚙️ Environment Configuration (IMPORTANT!)

Edit `.env` file and **CHANGE THESE VALUES**:

```bash
# Generate strong passwords
POSTGRES_PASSWORD=$(openssl rand -base64 32)
LANGFLOW_SUPERUSER_PASSWORD=$(openssl rand -base64 32)
LANGFLOW_SECRET_KEY=$(openssl rand -hex 32)

# Update domain
LANGFLOW_CORS_ORIGINS=https://your-actual-domain.com
```

**Critical Settings:**
- ✅ Change all passwords
- ✅ Generate new secret key
- ✅ Set your domain in CORS_ORIGINS
- ✅ Set `LANGFLOW_AUTO_LOGIN=false` for production

---

## 🔒 SSL Setup with Nginx (Production)

### 1. Install Nginx and Certbot

```bash
sudo apt update
sudo apt install nginx certbot python3-certbot-nginx -y
```

### 2. Configure Nginx

```bash
# Copy nginx configuration
sudo nano /etc/nginx/sites-available/langflow
# Paste content from nginx-langflow.conf
# Update 'yourdomain.com' with your domain

# Enable site
sudo ln -s /etc/nginx/sites-available/langflow /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 3. Get SSL Certificate

```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

### 4. Configure Firewall

```bash
sudo ufw enable
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw status
```

---

## 📊 Verify Deployment

```bash
# Check containers
docker compose ps

# Test health
curl http://localhost:7860/health

# View logs
docker compose logs -f langflow

# Check Nginx
sudo systemctl status nginx
curl -I https://yourdomain.com
```

---

## 🔧 Common Commands

```bash
# View logs
docker compose logs -f

# Restart services
docker compose restart

# Stop services
docker compose stop

# Start services
docker compose start

# Update Langflow
docker compose pull
docker compose up -d

# Backup database
docker compose exec postgres pg_dump -U langflow langflow > backup.sql

# Check disk usage
docker system df
```

---

## 📁 Server Directory Structure

After setup, your server should have:

```
~/langflow-deployment/
├── docker-compose.yml      # Production config
├── .env                    # Your secrets (keep safe!)
├── docker/
│   └── init.sql           # PostgreSQL init
├── DEPLOYMENT_GUIDE.md    # Full documentation
├── nginx-langflow.conf    # Nginx config (optional)
└── QUICK_DEPLOY.sh        # Deployment script
```

---

## 🎯 Access Your Langflow

**Without SSL (Testing):**
- http://your-server-ip:7860

**With SSL (Production):**
- https://yourdomain.com

**Default Login:**
- Username: admin (or what you set in LANGFLOW_SUPERUSER)
- Password: (what you set in LANGFLOW_SUPERUSER_PASSWORD)

---

## ⚠️ Security Checklist

Before going to production:

- [ ] Changed all default passwords
- [ ] Generated unique secret key
- [ ] Disabled auto-login
- [ ] Configured proper CORS origins
- [ ] Setup SSL/HTTPS
- [ ] Configured firewall
- [ ] Ports bound to localhost only (when using Nginx)
- [ ] Regular backup strategy in place
- [ ] Monitoring/logging configured

---

## 🆘 Troubleshooting

### Services won't start
```bash
docker compose logs langflow
docker compose logs postgres
```

### Port already in use
```bash
sudo lsof -i :7860
sudo lsof -i :5432
# Kill the process or change ports
```

### Permission errors
```bash
sudo chown -R $USER:$USER ~/langflow-deployment
```

### Database connection failed
```bash
# Check PostgreSQL
docker compose exec postgres psql -U langflow -d langflow -c "SELECT version();"

# Check environment variables
docker compose config
```

### Can't access from outside
```bash
# Check firewall
sudo ufw status

# Check Nginx
sudo nginx -t
sudo systemctl status nginx
```

---

## 📚 Full Documentation

For detailed instructions, troubleshooting, and advanced configuration:

**Read:** `DEPLOYMENT_GUIDE.md`

---

## 🎉 You're Ready!

1. Transfer the files to your server
2. Configure `.env` with your settings
3. Run the deployment script OR follow manual steps
4. Setup Nginx + SSL for production
5. Access your Langflow!

**Questions?** Check DEPLOYMENT_GUIDE.md or Langflow's official documentation.

---

**Current Status on Your Local Machine:** ✅ Running successfully
**Next Step:** Deploy to your server using the files created


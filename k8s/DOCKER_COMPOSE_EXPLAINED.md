# Docker Compose: How Two Containers Coordinate

## 🎯 Simple Explanation

When you run `docker-compose up`, Docker Compose creates a **virtual network** where both containers can talk to each other using their **service names** instead of IP addresses.

## 📊 Visual Flow

```
┌─────────────────────────────────────────────────────────┐
│  Your Computer / Azure Server                            │
│                                                          │
│  docker-compose up                                       │
│       │                                                  │
│       ├─ Creates Network: "langflow-network"            │
│       │                                                  │
│       ├─ Starts Container 1: "postgres"                 │
│       │   └─ Gets IP: 172.18.0.2                       │
│       │   └─ DNS Name: "postgres"                       │
│       │                                                  │
│       └─ Starts Container 2: "langflow"                │
│           └─ Gets IP: 172.18.0.3                        │
│           └─ DNS Name: "langflow"                       │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Internal Network: langflow-network             │  │
│  │                                                  │  │
│  │  Container: postgres                            │  │
│  │  IP: 172.18.0.2                                 │  │
│  │  Port: 5432                                     │  │
│  │                                                  │  │
│  │  Container: langflow                            │  │
│  │  IP: 172.18.0.3                                 │  │
│  │  Port: 7860                                     │  │
│  │                                                  │  │
│  │  Langflow connects using:                       │  │
│  │  "postgres:5432" ← Docker DNS resolves this    │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## 🔑 Key Concepts

### 1. Service Names = DNS Names

In `docker-compose.yml`:
```yaml
services:
  postgres:    # ← This becomes the DNS name
  langflow:   # ← This becomes the DNS name
```

**Inside containers, you can use:**
- `postgres` instead of `172.18.0.2`
- `langflow` instead of `172.18.0.3`

### 2. Connection String

```yaml
LANGFLOW_DATABASE_URL=postgresql://langflow:langflow@postgres:5432/langflow
                                                          └──────┘
                                                      Service name!
                                                      (Not IP address)
```

**How it works:**
1. Langflow container reads: `postgres:5432`
2. Docker DNS looks up "postgres" in the network
3. Finds: `172.18.0.2:5432`
4. Connects successfully!

### 3. Startup Order

```yaml
depends_on:
  postgres:
    condition: service_healthy
```

**What happens:**
1. Docker starts PostgreSQL first
2. Waits for health check to pass
3. Only then starts Langflow
4. Prevents connection errors!

### 4. Network Isolation

```yaml
networks:
  - langflow-network
```

**Benefits:**
- Containers can only see each other
- Isolated from other Docker containers
- Secure internal communication

## 🔄 Complete Startup Sequence

```
1. You run: docker-compose up
   │
2. Docker Compose reads docker-compose.yml
   │
3. Creates network: langflow-network
   │
4. Creates volumes:
   ├─ langflow-postgres (for database files)
   ├─ langflow-data (for Langflow config)
   └─ langflow-logs (for logs)
   │
5. Starts PostgreSQL container
   ├─ Pulls image: pgvector/pgvector:pg16
   ├─ Assigns to network: langflow-network
   ├─ Gets IP: 172.18.0.2
   ├─ Creates database: langflow
   ├─ Runs init.sql (enables pgvector)
   └─ Health check: pg_isready
   │
6. Waits for PostgreSQL to be healthy
   │
7. Starts Langflow container
   ├─ Pulls image: cera123/langflow:latest
   ├─ Assigns to network: langflow-network
   ├─ Gets IP: 172.18.0.3
   ├─ Reads environment variable:
   │   LANGFLOW_DATABASE_URL=postgresql://...@postgres:5432/langflow
   ├─ Resolves "postgres" → 172.18.0.2 (via Docker DNS)
   ├─ Connects to PostgreSQL
   ├─ Creates database tables (first time)
   └─ Starts web server on port 7860
   │
8. Both containers running and communicating!
```

## 🧪 Testing the Connection

### From Your Computer

```powershell
# Check containers are running
docker ps

# Check network
docker network inspect langflow-network

# Test PostgreSQL connection from Langflow container
docker exec langflow-app psql postgresql://langflow:langflow@postgres:5432/langflow -c "SELECT version();"
```

### From Inside Langflow Container

```powershell
# Enter Langflow container
docker exec -it langflow-app bash

# Test connection
psql postgresql://langflow:langflow@postgres:5432/langflow -c "SELECT 1;"

# Check environment variable
echo $LANGFLOW_DATABASE_URL
```

## 🔍 How Containers Communicate

### Method 1: Service Name (Recommended)

```yaml
LANGFLOW_DATABASE_URL=postgresql://user:pass@postgres:5432/db
                                                  └──────┘
                                              Service name
```

**Pros:**
- Works even if container IP changes
- Easy to read and maintain
- Docker handles DNS resolution

### Method 2: IP Address (Not Recommended)

```yaml
LANGFLOW_DATABASE_URL=postgresql://user:pass@172.18.0.2:5432/db
```

**Cons:**
- IP changes when container restarts
- Hard to maintain
- Breaks easily

## 📝 Important Points

1. **Same Network Required**
   - Both containers must be on `langflow-network`
   - Otherwise they can't communicate

2. **Service Names are Case-Sensitive**
   - `postgres` ≠ `Postgres`
   - Use exact service name from docker-compose.yml

3. **Ports are Internal**
   - `5432` inside network
   - `5432` on host (mapped)
   - Containers use internal ports

4. **Volumes are Shared**
   - Data persists even if containers restart
   - Stored on host filesystem

## 🚀 Quick Commands

```powershell
# Start both containers
docker-compose up -d

# View logs
docker-compose logs -f

# Stop containers
docker-compose down

# Restart containers
docker-compose restart

# View container status
docker-compose ps

# Execute command in container
docker-compose exec langflow bash
docker-compose exec postgres psql -U langflow -d langflow
```

## 🔐 Security Notes

1. **Passwords in docker-compose.yml**
   - Use environment variables for production
   - Don't commit passwords to git

2. **Network Isolation**
   - Containers are isolated by default
   - Only expose ports you need

3. **Volume Permissions**
   - Containers run as specific users
   - Check volume permissions

## ✅ Summary

**How it works:**
1. Docker Compose creates a network
2. Both containers join the network
3. They use service names to find each other
4. Docker DNS resolves names to IPs
5. Containers communicate internally
6. External access via mapped ports

**Key Takeaway:**
- Use **service names** in connection strings
- Docker handles the rest automatically!


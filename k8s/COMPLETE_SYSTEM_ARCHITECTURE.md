# Complete System Architecture: Langflow + PostgreSQL

## 🏗️ How the Two Containers Work Together

### Visual Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Docker Host / Azure Server                   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │         Docker Network: langflow-network                  │  │
│  │         (Bridge Network - Internal Communication)         │  │
│  │                                                            │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  Container 1: PostgreSQL (pgvector)                 │  │  │
│  │  │  ┌──────────────────────────────────────────────┐ │  │  │
│  │  │  │ Image: pgvector/pgvector:pg16                │ │  │  │
│  │  │  │ Container Name: langflow-postgres            │ │  │  │
│  │  │  │ Internal IP: 172.18.0.2 (example)           │ │  │  │
│  │  │  │                                                │ │  │  │
│  │  │  │ Ports:                                        │ │  │  │
│  │  │  │   - Internal: 5432                           │ │  │  │
│  │  │  │   - Host: 5432 → 5432 (mapped)               │ │  │  │
│  │  │  │                                                │ │  │  │
│  │  │  │ Environment:                                  │ │  │  │
│  │  │  │   POSTGRES_USER=langflow                      │ │  │  │
│  │  │  │   POSTGRES_PASSWORD=langflow                 │ │  │  │
│  │  │  │   POSTGRES_DB=langflow                       │ │  │  │
│  │  │  │                                                │ │  │  │
│  │  │  │ Storage:                                      │ │  │  │
│  │  │  │   Volume: langflow-postgres                   │ │  │  │
│  │  │  │   Mount: /var/lib/postgresql/data            │ │  │  │
│  │  │  │                                                │ │  │  │
│  │  │  │ Health Check:                                 │ │  │  │
│  │  │  │   pg_isready -U langflow -d langflow         │ │  │  │
│  │  │  └──────────────────────────────────────────────┘ │  │  │
│  │  │                                                    │  │  │
│  │  │  DNS Name: "postgres" (service name)            │  │  │
│  │  │  └──────────────────────────────────────────────┐ │  │  │
│  │  └──────────────────────────────────────────────────┘ │  │  │
│  │                          │                            │  │  │
│  │                          │ Internal Network           │  │  │
│  │                          │ Communication              │  │  │
│  │                          │ (via service name)        │  │  │
│  │                          ▼                            │  │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  Container 2: Langflow Application                 │  │  │
│  │  │  ┌──────────────────────────────────────────────┐ │  │  │
│  │  │  │ Image: cera123/langflow:latest              │ │  │  │
│  │  │  │ Container Name: langflow-app                │ │  │  │
│  │  │  │ Internal IP: 172.18.0.3 (example)           │ │  │  │
│  │  │  │                                                │ │  │  │
│  │  │  │ Ports:                                        │ │  │  │
│  │  │  │   - Internal: 7860                           │ │  │  │
│  │  │  │   - Host: 7860 → 7860 (mapped)              │ │  │  │
│  │  │  │                                                │ │  │  │
│  │  │  │ Environment:                                  │ │  │  │
│  │  │  │   LANGFLOW_DATABASE_URL=                     │ │  │  │
│  │  │  │   postgresql://langflow:langflow@            │ │  │  │
│  │  │  │   postgres:5432/langflow                     │ │  │  │
│  │  │  │   └─────────────────┘                        │ │  │  │
│  │  │  │   Uses service name "postgres"               │ │  │  │
│  │  │  │   (resolved by Docker DNS)                 │ │  │  │
│  │  │  │                                                │ │  │  │
│  │  │  │ Storage:                                      │ │  │  │
│  │  │  │   - langflow-data → /app/langflow           │ │  │  │
│  │  │  │   - langflow-logs → /app/logs               │ │  │  │
│  │  │  │                                                │ │  │  │
│  │  │  │ Health Check:                                 │ │  │  │
│  │  │  │   curl http://localhost:7860/health          │ │  │  │
│  │  │  │                                                │ │  │  │
│  │  │  │ Startup Dependency:                          │ │  │  │
│  │  │  │   Waits for postgres to be healthy          │ │  │  │
│  │  │  └──────────────────────────────────────────────┘ │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  External Access:                                              │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Host Port 7860 → Langflow Container (Port 7860)       │  │
│  │  Host Port 5432 → PostgreSQL Container (Port 5432)      │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## 🔄 Container Communication Flow

### 1. Docker Compose Startup Sequence

```
Step 1: Docker Compose Reads docker-compose.yml
   │
   ├─ Creates Network: langflow-network (bridge)
   │
   ├─ Creates Volumes:
   │   ├─ langflow-postgres (for DB data)
   │   ├─ langflow-data (for Langflow config)
   │   └─ langflow-logs (for Langflow logs)
   │
   ├─ Starts PostgreSQL Container
   │   ├─ Pulls image: pgvector/pgvector:pg16
   │   ├─ Assigns IP: 172.18.0.2 (example)
   │   ├─ Creates database: langflow
   │   ├─ Runs init.sql (enables pgvector extension)
   │   └─ Health check: pg_isready
   │
   └─ Waits for PostgreSQL to be healthy
       │
       └─ Starts Langflow Container
           ├─ Pulls image: cera123/langflow:latest
           ├─ Assigns IP: 172.18.0.3 (example)
           ├─ Reads LANGFLOW_DATABASE_URL
           ├─ Resolves "postgres" → 172.18.0.2 (via Docker DNS)
           ├─ Connects to PostgreSQL
           ├─ Creates database schema (first time)
           └─ Starts serving on port 7860
```

### 2. How Containers Find Each Other

**Docker Compose Service Discovery:**

1. **Service Names as DNS Names**
   - In `docker-compose.yml`, services are named: `langflow` and `postgres`
   - Docker Compose creates a DNS entry for each service
   - Containers can reach each other using service names

2. **Connection String Breakdown:**
   ```
   LANGFLOW_DATABASE_URL=postgresql://langflow:langflow@postgres:5432/langflow
                                                          └──────┘
                                                      Service name
                                                      (resolved by Docker DNS)
   ```

3. **Internal Network Communication:**
   - Both containers are on the same network: `langflow-network`
   - They can communicate using service names
   - No need to know actual IP addresses
   - Ports are accessible within the network

### 3. Data Flow

```
User Request
    │
    ▼
Host:7860 (External)
    │
    ▼
Langflow Container:7860
    │
    ├─ Processes Request
    │
    ├─ Needs Database Query
    │
    ├─ Connects to: postgres:5432
    │   │
    │   ├─ Docker DNS resolves "postgres"
    │   │   └─ → 172.18.0.2:5432
    │   │
    │   └─ PostgreSQL Container
    │       ├─ Executes Query
    │       └─ Returns Data
    │
    └─ Returns Response to User
```

## 🔐 Key Configuration Points

### 1. Network Configuration

```yaml
networks:
  langflow-network:
    driver: bridge
```

- **Bridge Network**: Creates an isolated network for containers
- **Service Discovery**: Containers can find each other by service name
- **Isolation**: Containers are isolated from other Docker networks

### 2. Dependency Management

```yaml
depends_on:
  postgres:
    condition: service_healthy
```

- **Startup Order**: Langflow waits for PostgreSQL
- **Health Check**: Only starts when PostgreSQL health check passes
- **Prevents Errors**: Avoids connection errors during startup

### 3. Environment Variables

**PostgreSQL Container:**
```yaml
POSTGRES_USER: langflow
POSTGRES_PASSWORD: langflow
POSTGRES_DB: langflow
```

**Langflow Container:**
```yaml
LANGFLOW_DATABASE_URL=postgresql://langflow:langflow@postgres:5432/langflow
```

**Critical:** Username and password must match!

### 4. Volume Persistence

**PostgreSQL:**
- Volume: `langflow-postgres`
- Mount: `/var/lib/postgresql/data`
- Contains: Database files, indexes, vector data

**Langflow:**
- Volume: `langflow-data` → `/app/langflow` (config, cache)
- Volume: `langflow-logs` → `/app/logs` (application logs)

## 🌐 Azure Deployment Options

### Option 1: Azure Container Instances (ACI) - Simple

**Best for:** Quick deployment, single region, small scale

**Pros:**
- Simple setup
- No cluster management
- Pay per container
- Quick to deploy

**Cons:**
- Limited scaling
- No built-in load balancing
- Containers must be in same resource group

### Option 2: Azure Kubernetes Service (AKS) - Production

**Best for:** Production, scaling, high availability

**Pros:**
- Auto-scaling
- Load balancing
- High availability
- Production-ready

**Cons:**
- More complex setup
- Requires Kubernetes knowledge
- Higher cost

### Option 3: Azure App Service - Managed

**Best for:** Simple web apps, managed PostgreSQL

**Pros:**
- Fully managed
- Built-in scaling
- Easy deployment

**Cons:**
- Less control
- May need Azure Database for PostgreSQL (separate service)

## 📋 Complete Azure Deployment Guide

See the next section for step-by-step Azure configuration.


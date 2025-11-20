# Database Coordination with Langflow Image

## 🔄 How Your Docker Image Connects to PostgreSQL

### Architecture Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                        │
│                    (namespace: prod)                         │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  PostgreSQL Deployment                                │   │
│  │  ┌────────────────────────────────────────────────┐  │   │
│  │  │ Pod: postgres-xxxxx                            │  │   │
│  │  │ Image: pgvector/pgvector:pg16                  │  │   │
│  │  │ Port: 5432                                      │  │   │
│  │  │                                                 │  │   │
│  │  │ Environment:                                     │  │   │
│  │  │   POSTGRES_USER: "langflow"                     │  │   │
│  │  │   POSTGRES_PASSWORD: "ChangeMe..."             │  │   │
│  │  │   POSTGRES_DB: "langflow"                      │  │   │
│  │  │                                                 │  │   │
│  │  │ Storage: postgres-pvc (20Gi)                   │  │   │
│  │  └────────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────┘   │
│                          │                                   │
│                          │ Service: postgres-service         │
│                          │ (ClusterIP: port 5432)           │
│                          ▼                                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Langflow Deployment                                  │   │
│  │  ┌────────────────────────────────────────────────┐  │   │
│  │  │ Init Container: wait-for-postgres              │  │   │
│  │  │ - Checks: nc -z postgres-service 5432          │  │   │
│  │  │ - Waits until PostgreSQL is ready             │  │   │
│  │  └────────────────────────────────────────────────┘  │   │
│  │                          │                            │   │
│  │                          ▼                            │   │
│  │  ┌────────────────────────────────────────────────┐  │   │
│  │  │ Pod: langflow-api-prod-xxxxx                    │  │   │
│  │  │ Image: cera123/langflow:latest                 │  │   │
│  │  │ Port: 7860                                      │  │   │
│  │  │                                                 │  │   │
│  │  │ Environment Variable:                           │  │   │
│  │  │   LANGFLOW_DATABASE_URL=                       │  │   │
│  │  │   "postgresql://langflow:ChangeMe...@          │  │   │
│  │  │    postgres-service:5432/langflow"            │  │   │
│  │  │                                                 │  │   │
│  │  │ Storage:                                        │  │   │
│  │  │   - langflow-data-pvc (10Gi) → /app/langflow  │  │   │
│  │  │   - langflow-logs-pvc (5Gi) → /app/logs       │  │   │
│  │  └────────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 📋 Connection Details

### 1. Connection String Format

```
postgresql://[username]:[password]@[host]:[port]/[database]
```

**In Your Setup:**
```
postgresql://langflow:ChangeMeToStrongPassword123!@postgres-service:5432/langflow
```

**Components:**
- **Username**: `langflow` (must match POSTGRES_USER)
- **Password**: `ChangeMeToStrongPassword123!` (must match POSTGRES_PASSWORD)
- **Host**: `postgres-service` (Kubernetes Service name, not pod IP)
- **Port**: `5432` (PostgreSQL default port)
- **Database**: `langflow` (must match POSTGRES_DB)

### 2. Service Discovery

Kubernetes uses **DNS-based service discovery**:

- When Langflow tries to connect to `postgres-service:5432`
- Kubernetes DNS resolves `postgres-service` to the ClusterIP
- Traffic is routed to any PostgreSQL pod with label `app: postgres`
- This allows PostgreSQL pods to be replaced without breaking the connection

### 3. Startup Sequence

```
1. PostgreSQL Pod Starts
   ├─ Creates database: langflow
   ├─ Runs init.sql (enables pgvector extension)
   └─ Becomes ready (readiness probe passes)

2. PostgreSQL Service Available
   └─ DNS: postgres-service → ClusterIP

3. Langflow Init Container Runs
   ├─ Checks: nc -z postgres-service 5432
   ├─ Waits if PostgreSQL not ready
   └─ Exits when PostgreSQL is ready

4. Langflow Container Starts
   ├─ Reads LANGFLOW_DATABASE_URL from Secret
   ├─ Connects to postgres-service:5432
   ├─ Runs database migrations (if needed)
   └─ Starts serving on port 7860
```

## 🔐 Credential Matching

### Critical: Credentials Must Match!

**PostgreSQL Secret** (`postgres-secret`):
```yaml
POSTGRES_USER: "langflow"
POSTGRES_PASSWORD: "ChangeMeToStrongPassword123!"
```

**Langflow Secret** (`langflow-secret`):
```yaml
LANGFLOW_DATABASE_URL: "postgresql://langflow:ChangeMeToStrongPassword123!@postgres-service:5432/langflow"
```

**⚠️ IMPORTANT:** If you change the PostgreSQL password, you MUST update the Langflow connection string!

## 🗄️ Database Initialization

### First-Time Setup

When PostgreSQL starts for the first time:

1. **Creates Database**: `langflow` (via POSTGRES_DB env var)
2. **Runs init.sql**: 
   - Enables `pgvector` extension (for vector operations)
   - Sets timezone to UTC
   - Grants permissions to `langflow` user

### Langflow Schema Creation

When Langflow connects for the first time:

- Automatically creates required tables:
  - Users, flows, components
  - Message history
  - Logs and metadata
- Uses Alembic migrations (built into your image)

## 📊 Data Persistence

### PostgreSQL Storage
- **PVC**: `postgres-pvc` (20Gi)
- **Mount**: `/var/lib/postgresql/data`
- **Contains**: Database files, indexes, vector data

### Langflow Storage
- **Data PVC**: `langflow-data-pvc` (10Gi)
  - Mount: `/app/langflow`
  - Contains: Configuration, cached data
- **Logs PVC**: `langflow-logs-pvc` (5Gi)
  - Mount: `/app/logs`
  - Contains: Application logs

## 🔍 Troubleshooting Connection Issues

### Check PostgreSQL is Running
```bash
kubectl get pods -n prod -l app=postgres
kubectl logs -n prod -l app=postgres
```

### Check Service is Available
```bash
kubectl get svc -n prod postgres-service
kubectl describe svc -n prod postgres-service
```

### Test Connection from Langflow Pod
```bash
# Get Langflow pod name
kubectl get pods -n prod -l app=langflow-api-prod

# Test connection
kubectl exec -n prod <langflow-pod> -- \
  python -c "import psycopg2; psycopg2.connect('postgresql://langflow:ChangeMeToStrongPassword123!@postgres-service:5432/langflow')"
```

### Check Environment Variables
```bash
kubectl exec -n prod <langflow-pod> -- env | grep LANGFLOW_DATABASE_URL
```

### Common Issues

1. **Password Mismatch**
   - Error: `password authentication failed`
   - Fix: Ensure passwords match in both secrets

2. **Service Not Found**
   - Error: `could not translate host name "postgres-service"`
   - Fix: Check service exists: `kubectl get svc -n prod`

3. **Database Doesn't Exist**
   - Error: `database "langflow" does not exist`
   - Fix: Check POSTGRES_DB in postgres-config ConfigMap

4. **Connection Timeout**
   - Error: `connection timeout`
   - Fix: Check PostgreSQL pod is running and ready

## 🔄 Updating Database Connection

### To Change Database Password:

1. **Update PostgreSQL Secret:**
```bash
kubectl edit secret postgres-secret -n prod
# Change POSTGRES_PASSWORD
```

2. **Update Langflow Secret:**
```bash
kubectl edit secret langflow-secret -n prod
# Update LANGFLOW_DATABASE_URL with new password
```

3. **Restart Both Deployments:**
```bash
kubectl rollout restart deployment/postgres -n prod
kubectl rollout restart deployment/langflow-api-prod -n prod
```

## 📝 Summary

Your Docker image (`cera123/langflow:latest`) connects to PostgreSQL through:

1. **Environment Variable**: `LANGFLOW_DATABASE_URL` (set in Kubernetes Secret)
2. **Service Discovery**: Uses Kubernetes Service name `postgres-service`
3. **Startup Coordination**: Init container waits for PostgreSQL
4. **Automatic Setup**: Langflow creates schema on first connection
5. **Persistent Storage**: Both use PVCs for data persistence

The connection is **fully automated** - your image just needs the correct `LANGFLOW_DATABASE_URL` environment variable, and it will handle the rest!


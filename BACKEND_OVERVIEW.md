# Langflow Backend Overview

## 📁 Directory Structure

```
src/backend/
├── base/
│   └── langflow/          # Main Langflow backend package
│       ├── __main__.py    # CLI entry point (langflow run command)
│       ├── main.py        # FastAPI app creation (create_app, setup_app)
│       ├── server.py      # Gunicorn server configuration
│       ├── settings.py    # Configuration settings
│       │
│       ├── api/           # API routes and endpoints
│       │   ├── router.py  # Main router that includes all API routers
│       │   ├── v1/        # API version 1 endpoints
│       │   │   ├── chat.py
│       │   │   ├── flows.py
│       │   │   ├── users.py
│       │   │   ├── files.py
│       │   │   └── ... (25+ route files)
│       │   └── v2/        # API version 2 endpoints
│       │
│       ├── components/   # Langflow components (411+ component files)
│       ├── services/      # Business logic services (137+ service files)
│       ├── schema/        # Pydantic schemas for data validation
│       ├── graph/         # Flow graph processing logic
│       ├── core/          # Core functionality (Celery, etc.)
│       ├── database/      # Database models and migrations
│       └── utils/         # Utility functions
│
├── langflow/              # Version information
└── tests/                 # Test files
```

## 🏗️ Architecture Overview

### 1. **Entry Points**

#### CLI Entry Point (`__main__.py`)
- Command: `langflow run` or `python -m langflow`
- Uses Typer for CLI interface
- Handles startup progress, configuration, and server launch
- Supports both Windows (uvicorn) and Unix (Gunicorn) systems

#### FastAPI App (`main.py`)
- `create_app()`: Creates the FastAPI application instance
- `setup_app()`: Sets up the app with static files (frontend)
- Factory pattern: `langflow.main:create_app` (used by uvicorn)

### 2. **Application Lifecycle**

The app uses FastAPI's `lifespan` context manager:

**Startup:**
1. Initialize settings service
2. Initialize all services (database, cache, etc.)
3. Setup LLM caching
4. Copy profile pictures
5. Initialize default superuser (if auto-login enabled)
6. Load component bundles
7. Cache component types
8. Create/update starter projects
9. Initialize agentic global variables
10. Start telemetry service
11. Start MCP Composer service
12. Sync flows from filesystem

**Shutdown:**
1. Stop telemetry service
2. Teardown all services
3. Cleanup temporary directories

### 3. **API Structure**

#### Main Router (`api/router.py`)
- Includes all API routers (v1 and v2)
- Health check router
- Log router

#### API v1 Endpoints (`api/v1/`)
- **chat.py**: Chat endpoints
- **flows.py**: Flow management (CRUD operations)
- **users.py**: User management
- **files.py**: File upload/download
- **endpoints.py**: Custom API endpoints
- **projects.py**: Project management
- **knowledge_bases.py**: Knowledge base operations
- **mcp.py**: MCP (Model Context Protocol) endpoints
- And more...

### 4. **Services Layer**

Located in `services/` directory:
- **Database Service**: SQLModel/SQLAlchemy database operations
- **Settings Service**: Configuration management
- **Cache Service**: Caching layer
- **Telemetry Service**: Analytics and error tracking
- **Auth Service**: Authentication and authorization
- **Queue Service**: Background task processing
- And more...

### 5. **Components**

Located in `components/` directory:
- 411+ component files
- Each component is a Langflow node type
- Examples: LLM components, prompt templates, data processors, etc.

## 🚀 How to Start the Backend

### Method 1: Using Make (Recommended for Development)

```bash
# Start backend with auto-reload (development mode)
make backend

# With custom port
make backend port=8080

# With auto-login enabled
make backend login=true
```

This runs:
```bash
uv run uvicorn \
  --factory langflow.main:create_app \
  --host 0.0.0.0 \
  --port 7860 \
  --reload \
  --env-file .env \
  --loop asyncio
```

### Method 2: Using Langflow CLI

```bash
# Install dependencies first
uv sync

# Run Langflow (includes frontend)
uv run langflow run

# Backend only
uv run langflow run --backend-only

# Custom port
uv run langflow run --port 8080

# With environment file
uv run langflow run --env-file .env
```

### Method 3: Direct Python Execution

```bash
# Using uvicorn directly
uv run uvicorn \
  --factory langflow.main:create_app \
  --host 0.0.0.0 \
  --port 7860 \
  --reload
```

### Method 4: Python Module

```bash
python -m langflow run
```

## 🔧 Configuration

### Environment Variables

The backend reads from `.env` file. Key variables:

- `LANGFLOW_HOST`: Server host (default: 0.0.0.0)
- `LANGFLOW_PORT`: Server port (default: 7860)
- `LANGFLOW_DATABASE_URL`: Database connection string
- `LANGFLOW_AUTO_LOGIN`: Enable auto-login for development
- `LANGFLOW_CORS_ORIGINS`: CORS allowed origins
- `LFX_DEV`: Enable dynamic component loading (for development)

### Settings Service

Settings are managed by `get_settings_service()` which reads from:
1. Environment variables
2. `.env` file
3. Default values

## 📊 Key Files to Understand

1. **`main.py`**: FastAPI app creation and middleware setup
2. **`__main__.py`**: CLI entry point and server startup
3. **`api/router.py`**: API route registration
4. **`services/utils.py`**: Service initialization
5. **`settings.py`**: Configuration management

## 🧪 Testing

```bash
# Run all tests
make tests

# Unit tests only
make unit_tests

# Integration tests
make integration_tests
```

## 📝 Development Tips

1. **Component Development**: Set `LFX_DEV=1` to load components dynamically
2. **Auto-reload**: The `make backend` command enables auto-reload by default
3. **Database**: Uses SQLite by default (can be configured for PostgreSQL)
4. **Logging**: Check logs in console or configure log file in settings

## 🔍 Health Check

Once started, check if backend is running:
```bash
curl http://localhost:7860/health
```

Should return:
```json
{ "status": "ok" }
```

## 📚 Additional Resources

- `DEVELOPMENT.md`: Detailed development guide
- `README.md`: Project overview
- API Documentation: Available at `/docs` when server is running (Swagger UI)






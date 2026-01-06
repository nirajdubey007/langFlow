# Quick Start: Langflow Backend

## Prerequisites

You need to install `uv` first (Python package manager):

```bash
# macOS/Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Or using Homebrew (macOS)
brew install uv

# Or using pip
pip install uv
```

## Step 1: Install Dependencies

```bash
# From the project root
cd /Users/niraj/Desktop/langFlowBrained/langFlow

# Install backend dependencies
uv sync
```

## Step 2: Create .env File (Optional)

Create a `.env` file in the project root if you want custom configuration:

```bash
# Create .env file
cat > .env << EOF
LANGFLOW_HOST=0.0.0.0
LANGFLOW_PORT=7860
LANGFLOW_AUTO_LOGIN=true
EOF
```

## Step 3: Start the Backend

### Option A: Using Make (Recommended)

```bash
make backend
```

This will:
- Setup environment
- Install backend dependencies
- Start uvicorn server with auto-reload
- Run on http://0.0.0.0:7860

### Option B: Using Langflow CLI

```bash
uv run langflow run --backend-only
```

### Option C: Direct uvicorn

```bash
uv run uvicorn \
  --factory langflow.main:create_app \
  --host 0.0.0.0 \
  --port 7860 \
  --reload \
  --env-file .env \
  --loop asyncio
```

## Step 4: Verify Backend is Running

Open a new terminal and check:

```bash
curl http://localhost:7860/health
```

Should return:
```json
{ "status": "ok" }
```

## Troubleshooting

### Port Already in Use

If port 7860 is already in use:

```bash
# Kill process on port 7860
lsof -ti:7860 | xargs kill -9

# Or use a different port
make backend port=8080
```

### Missing Dependencies

```bash
# Reinstall dependencies
uv sync --reinstall
```

### Component Development Mode

If you're developing components, enable dynamic loading:

```bash
LFX_DEV=1 make backend
```

## What Happens When Backend Starts

1. **Initialization**: Services are initialized (database, cache, etc.)
2. **Database**: SQLite database is created/connected
3. **Components**: All Langflow components are loaded
4. **Starter Projects**: Default starter projects are created
5. **API Routes**: All API endpoints are registered
6. **Server**: Uvicorn server starts listening on port 7860

## API Endpoints

Once running, you can access:

- **Health Check**: http://localhost:7860/health
- **API Docs**: http://localhost:7860/docs (Swagger UI)
- **API v1**: http://localhost:7860/api/v1/...

## Next Steps

- Start the frontend: `make frontend` (in a separate terminal)
- Access the UI: http://localhost:3000 (development) or http://localhost:7860 (production)





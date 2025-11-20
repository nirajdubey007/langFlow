# -----------------------
# Stage 1 — Frontend build
# -----------------------
    FROM node:20-slim AS frontend-builder
    WORKDIR /work/frontend
     
    # copy only package files first for better caching
    COPY src/frontend/package*.json ./
    RUN npm i --legacy-peer-deps
     
    # copy source and build
    COPY src/frontend/ ./
    RUN npm run build
     
     
    # -----------------------
    # Stage 2 — Backend (final)
    # -----------------------
    FROM python:3.12-slim
     
    # Install OS packages needed for build/runtime (keep minimal)
    RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        gcc \
        git \
        curl \
        libpq-dev \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*
     
    # Create non-root user (UID 1000 to match your K8s runAsUser)
    ARG APP_USER=appuser
    ARG APP_UID=1000
    RUN useradd --create-home --uid ${APP_UID} ${APP_USER}
     
    # Create directories
    WORKDIR /app
    RUN mkdir -p /app/langflow /app/logs
     
    # Create virtualenv (as root) in a location outside /app to avoid modifying /app files:
    RUN python -m venv /opt/venv
     
    # Ensure the venv Python is used for all subsequent RUN steps
    ENV PATH="/opt/venv/bin:${PATH}"
     
    # Upgrade pip & wheel
    RUN pip install --upgrade pip setuptools wheel
     
    # Copy pyproject/lock (if present) and backend source into image
    # (Copy minimal metadata first to take advantage of layer caching)
    COPY pyproject.toml uv.lock README.md ./
    COPY src/backend/base/pyproject.toml src/backend/base/uv.lock ./src/backend/base/
    COPY src/backend/base/README.md ./src/backend/base/
     
    # Copy langflow source into /app/langflow (we will pip install from source)
    COPY src/backend/base/langflow /app/langflow
     
    # Install the langflow package (from source). This will create an egg-link in site-packages
    # but the actual package files are in /app/langflow (which we will own). Install other deps too.
    RUN pip install --no-cache-dir /app/langflow
     
    # Copy frontend build from frontend-builder into the package frontend folder
    COPY --from=frontend-builder /work/frontend/build /app/langflow/frontend
     
    # Make sure the application directories are writable by runtime user (only these)
    RUN chown -R ${APP_UID}:${APP_UID} /app/langflow /app/logs \
    && chmod -R 755 /app/langflow \
    && chmod -R 755 /app/logs
     
    # Set environment variables (explicit)
    ENV LANGFLOW_HOST=0.0.0.0
    ENV LANGFLOW_PORT=7860
    ENV LANGFLOW_LOG_DIR=/app/logs
    ENV PYTHONPATH=/app
     
    # Expose port
    EXPOSE 7860
     
    # Switch to the non-root user for runtime
    USER ${APP_USER}
     
    # Healthcheck (runs as non-root)
    HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
      CMD curl -f http://localhost:7860/health || exit 1
     
    # Start the app using the venv python to make sure we run from the same environment
    CMD ["/opt/venv/bin/python", "-m", "langflow", "run", "--host", "0.0.0.0", "--port", "7860"]
# Multi-stage Dockerfile for Langflow
# Stage 1: Build Frontend
FROM node:20-slim AS frontend-builder

WORKDIR /app/frontend

# Copy frontend package files
COPY src/frontend/package*.json ./

# Install frontend dependencies
RUN npm ci --legacy-peer-deps

# Copy frontend source
COPY src/frontend/ ./

# Build frontend (output goes to 'build' directory)
RUN npm run build

# Stage 2: Build Backend with Frontend
FROM python:3.12-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    postgresql-client \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy dependency files
COPY pyproject.toml README.md ./
COPY src/backend/base/pyproject.toml src/backend/base/README.md ./src/backend/base/

# Install uv
RUN pip install --no-cache-dir uv

# Copy backend source
COPY src/backend/base/langflow ./src/backend/base/langflow

# Install Python dependencies with PostgreSQL support
RUN pip install --no-cache-dir -e ./src/backend/base[postgresql]

# Copy built frontend from frontend-builder stage
# The build output is in 'build' directory, not 'dist'
COPY --from=frontend-builder /app/frontend/build ./src/backend/base/langflow/frontend

# Create necessary directories and fix permissions
RUN mkdir -p /app/langflow /app/logs && \
    chmod -R 755 /app/langflow /app/logs

# Set environment variables
ENV LANGFLOW_HOST=0.0.0.0
ENV LANGFLOW_PORT=7860
ENV PYTHONPATH=/app

# Expose port
EXPOSE 7860

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=5 \
    CMD curl -f http://localhost:7860/health || exit 1

# Run the application
CMD ["python", "-m", "langflow", "run", "--host", "0.0.0.0", "--port", "7860"]


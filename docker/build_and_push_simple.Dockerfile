# syntax=docker/dockerfile:1
# Simplified Dockerfile for Langflow - Windows-friendly build

################################
# BUILDER-BASE
################################
FROM --platform=linux/amd64 ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder

WORKDIR /app

ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV RUSTFLAGS='--cfg reqwest_unstable'

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    npm \
    gcc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY uv.lock README.md pyproject.toml ./
COPY src/backend/base/README.md src/backend/base/README.md
COPY src/backend/base/uv.lock src/backend/base/uv.lock
COPY src/backend/base/pyproject.toml src/backend/base/pyproject.toml

RUN uv sync --frozen --no-install-project --no-editable --extra postgresql

# Copy source code
COPY ./src /app/src

# Build frontend
COPY src/frontend /tmp/src/frontend
WORKDIR /tmp/src/frontend
RUN npm ci && npm run build && \
    cp -r build /app/src/backend/langflow/frontend && \
    rm -rf /tmp/src/frontend

# Install project
WORKDIR /app
RUN uv sync --frozen --no-editable --extra postgresql

################################
# RUNTIME
################################
FROM --platform=linux/amd64 python:3.12.3-slim AS runtime

# Install runtime dependencies (without Node.js)
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    curl \
    git \
    libpq5 \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd user -u 1000 -g 0 --no-create-home --home-dir /app/data

# Copy virtual environment from builder
COPY --from=builder --chown=1000 /app/.venv /app/.venv

# Set environment
ENV PATH="/app/.venv/bin:$PATH"
ENV LANGFLOW_HOST=0.0.0.0
ENV LANGFLOW_PORT=7860

# Labels
LABEL org.opencontainers.image.title=langflow
LABEL org.opencontainers.image.authors=['Langflow']
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.url=https://github.com/langflow-ai/langflow
LABEL org.opencontainers.image.source=https://github.com/langflow-ai/langflow

# Switch to non-root user
USER user
WORKDIR /app

CMD ["langflow", "run"]



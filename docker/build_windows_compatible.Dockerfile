# syntax=docker/dockerfile:1
# Windows-Compatible Langflow Dockerfile
# This version works around Windows Docker Desktop platform issues

################################
# BUILDER STAGE
################################
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder

WORKDIR /app

ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV RUSTFLAGS='--cfg reqwest_unstable'

# Install build dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    npm \
    gcc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=README.md,target=README.md \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=src/backend/base/README.md,target=src/backend/base/README.md \
    --mount=type=bind,source=src/backend/base/uv.lock,target=src/backend/base/uv.lock \
    --mount=type=bind,source=src/backend/base/pyproject.toml,target=src/backend/base/pyproject.toml \
    uv sync --frozen --no-install-project --no-editable --extra postgresql

# Copy source
COPY ./src /app/src

# Build frontend
COPY src/frontend /tmp/src/frontend
WORKDIR /tmp/src/frontend
RUN --mount=type=cache,target=/root/.npm \
    npm ci && \
    npm run build && \
    cp -r build /app/src/backend/langflow/frontend && \
    rm -rf /tmp/src/frontend

# Finalize Python installation
WORKDIR /app
COPY ./pyproject.toml ./uv.lock ./README.md ./

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-editable --extra postgresql

################################
# RUNTIME STAGE
################################
FROM python:3.12.3-slim AS runtime

# Install runtime dependencies (NO Node.js needed)
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    curl \
    git \
    libpq5 \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create user
RUN useradd user -u 1000 -g 0 --no-create-home --home-dir /app/data

# Copy virtual environment
COPY --from=builder --chown=1000 /app/.venv /app/.venv

# Environment
ENV PATH="/app/.venv/bin:$PATH"
ENV LANGFLOW_HOST=0.0.0.0
ENV LANGFLOW_PORT=7860

# Metadata
LABEL org.opencontainers.image.title=langflow
LABEL org.opencontainers.image.authors=['Langflow']
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.url=https://github.com/langflow-ai/langflow
LABEL org.opencontainers.image.source=https://github.com/langflow-ai/langflow

USER user
WORKDIR /app

CMD ["langflow", "run"]



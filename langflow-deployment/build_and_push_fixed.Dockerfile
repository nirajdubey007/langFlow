# syntax=docker/dockerfile:1.6
# Enables BuildKit multi-platform features

########################################
# BUILDER STAGE
########################################
FROM --platform=$BUILDPLATFORM python:3.12-slim-bookworm AS builder

# Install build tools and UV package manager
WORKDIR /app
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential git curl npm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/*

# Install uv manually since ghcr.io/astral-sh/uv is AMD-only
RUN pip install uv

# Copy dependency files
COPY pyproject.toml uv.lock README.md ./
COPY src/backend/base/pyproject.toml src/backend/base/uv.lock src/backend/base/README.md src/backend/base/

# Enable bytecode compilation and caching
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV RUSTFLAGS="--cfg reqwest_unstable"

# Sync dependencies (no editable mode, no install project yet)
# Cache mount removed to save disk space
RUN uv sync --frozen --no-install-project --no-editable --extra postgresql && \
    rm -rf /tmp/* /var/tmp/* /root/.cache/*

# Copy project source
COPY src /app/src

# Build frontend
WORKDIR /app/src/frontend
# Set Node.js memory limit to 2GB (balance between build success and disk usage)
ENV NODE_OPTIONS="--max-old-space-size=2048"
RUN npm ci --prefer-offline --no-audit && \
    npm run build && \
    mkdir -p /app/src/backend/langflow/frontend && \
    cp -r build /app/src/backend/langflow/frontend && \
    rm -rf node_modules .npm /root/.npm /tmp/* /var/tmp/*

# Finalize Python dependencies
WORKDIR /app
# Cache mount removed to save disk space
RUN uv sync --frozen --no-editable --extra postgresql && \
    rm -rf /tmp/* /var/tmp/* /root/.cache/*


########################################
# RUNTIME STAGE
########################################
FROM --platform=$TARGETPLATFORM python:3.12-slim-bookworm AS runtime

# Install minimal runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl git libpq5 ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.cache/*

# Copy venv from builder
WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /app/src /app/src

# Ensure virtualenv binaries are in PATH
ENV PATH="/app/.venv/bin:$PATH"

# Metadata
LABEL org.opencontainers.image.title="Langflow"
LABEL org.opencontainers.image.authors="Langflow Team"
LABEL org.opencontainers.image.license="MIT"
LABEL org.opencontainers.image.source="https://github.com/langflow-ai/langflow"

# Create and switch to a non-root user
RUN useradd -u 1000 -m user
USER user

# App runtime configuration
ENV LANGFLOW_HOST=0.0.0.0
ENV LANGFLOW_PORT=7860

EXPOSE 7860

# Default command
CMD ["langflow", "run"]

# syntax=docker/dockerfile:1
# Keep this syntax directive! It's used to enable Docker BuildKit

################################
# BUILDER-BASE
# Used to build deps + create our virtual environment
################################

FROM --platform=linux/amd64 ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder

# Install the project into `/app`
WORKDIR /app

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy

# Set RUSTFLAGS for reqwest unstable features needed by apify-client v2.0.0
ENV RUSTFLAGS='--cfg reqwest_unstable'

RUN apt-get update && apt-get upgrade -y && apt-get install --no-install-recommends -y build-essential git npm gcc && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=README.md,target=README.md \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=src/backend/base/README.md,target=src/backend/base/README.md \
    --mount=type=bind,source=src/backend/base/uv.lock,target=src/backend/base/uv.lock \
    --mount=type=bind,source=src/backend/base/pyproject.toml,target=src/backend/base/pyproject.toml \
    uv sync --frozen --no-install-project --no-editable --extra postgresql

COPY ./src /app/src

COPY src/frontend /tmp/src/frontend
WORKDIR /tmp/src/frontend
RUN --mount=type=cache,target=/root/.npm \
    npm ci && npm run build && cp -r build /app/src/backend/langflow/frontend && rm -rf /tmp/src/frontend

WORKDIR /app
COPY ./pyproject.toml /app/pyproject.toml
COPY ./uv.lock /app/uv.lock
COPY ./README.md /app/README.md

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-editable --extra postgresql

################################
# RUNTIME
# Setup user, utilities and copy the virtual environment only
################################
FROM --platform=linux/amd64 python:3.12.3-slim AS runtime

# Install runtime dependencies in separate steps for better error handling
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends curl git libpq5 ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create user
RUN useradd user -u 1000 -g 0 --no-create-home --home-dir /app/data

COPY --from=builder --chown=1000 /app/.venv /app/.venv

# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"

LABEL org.opencontainers.image.title=langflow
LABEL org.opencontainers.image.authors=['Langflow']
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.url=https://github.com/langflow-ai/langflow
LABEL org.opencontainers.image.source=https://github.com/langflow-ai/langflow

USER user
WORKDIR /app

ENV LANGFLOW_HOST=0.0.0.0
ENV LANGFLOW_PORT=7860

CMD ["langflow", "run"]

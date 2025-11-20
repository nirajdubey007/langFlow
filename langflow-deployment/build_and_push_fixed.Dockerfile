# syntax=docker/dockerfile:1.6
 
########################################
# BUILDER STAGE
########################################
FROM python:3.12-slim-bookworm AS builder
 
WORKDIR /app
 
# Install build tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential git curl npm pkg-config libpq-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
 
# Create venv
RUN python -m venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"
 
# Install uv inside venv
RUN pip install uv
 
# ----------------------------
# 🔥 Copy full project first (important)
# ----------------------------
COPY . /app
 
# ----------------------------
# 🔥 Install dependencies AFTER source is present
# ----------------------------
RUN uv sync --frozen --extra postgresql
 
# ----------------------------
# Build frontend
# ----------------------------
WORKDIR /app/src/frontend
RUN npm ci --prefer-offline --no-audit && npm run build
 
# Copy built frontend to backend
RUN mkdir -p /app/src/backend/langflow/frontend && \
    cp -r build /app/src/backend/langflow/frontend
 
########################################
# RUNTIME STAGE
########################################
FROM python:3.12-slim-bookworm AS runtime
 
WORKDIR /app
 
# Install required runtime libs
RUN apt-get update && \
    apt-get install -y --no-install-recommends libpq5 curl git ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
 
# Copy venv + source
COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /app/src /app/src
 
ENV PATH="/app/.venv/bin:$PATH"
 
# Create user
RUN useradd -u 1000 -m user
USER user
 
ENV LANGFLOW_HOST=0.0.0.0
ENV LANGFLOW_PORT=7860
 
EXPOSE 7860
 
CMD ["/app/.venv/bin/python", "-m", "langflow", "run", "--host", "0.0.0.0", "--port", "7860"]
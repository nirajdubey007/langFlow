# syntax=docker/dockerfile:1.6
########################################
# BUILDER STAGE
########################################
FROM python:3.12-slim-bookworm AS builder
WORKDIR /app
 
# Install build tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential git curl npm && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
 
# ----------------------------
# 🔥 CREATE VENV (YOU DIDN'T HAVE THIS)
# ----------------------------
RUN python -m venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"
 
# Install uv inside venv
RUN pip install uv
 
# Copy dependency files
COPY pyproject.toml uv.lock README.md ./
COPY src/backend/base/pyproject.toml src/backend/base/uv.lock src/backend/base/
 
# Install Python dependencies into venv
RUN uv sync --frozen --no-install-project --no-editable --extra postgresql
 
# Copy full source
COPY src /app/src
 
# Build frontend
WORKDIR /app/src/frontend
RUN npm ci --prefer-offline --no-audit && \
    npm run build && \
    mkdir -p /app/src/backend/langflow/frontend && \
    cp -r build /app/src/backend/langflow/frontend
 
# ----------------------------
# 🔥 INSTALL LANGFLOW FROM SOURCE (YOU DIDN'T HAVE THIS)
# ----------------------------
WORKDIR /app
RUN pip install --no-cache-dir /app/src/backend/langflow
 
# ----------------------------
# 🔥 FIX PERMISSIONS HERE (YOU DID IT IN K8S)
# ----------------------------
RUN chown -R 1000:1000 /app/.venv /app/src
 
########################################
# RUNTIME STAGE
########################################
FROM python:3.12-slim-bookworm AS runtime
 
WORKDIR /app
 
# Install minimal runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl git libpq5 ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
 
# Copy venv + src from builder
COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /app/src /app/src
 
ENV PATH="/app/.venv/bin:$PATH"
 
# Create runtime user
RUN useradd -u 1000 -m user
USER user
 
ENV LANGFLOW_HOST=0.0.0.0
ENV LANGFLOW_PORT=7860
 
EXPOSE 7860
 
# ----------------------------
# 🔥 USE VENV PYTHON (YOUR OLD FILE DID NOT)
# ----------------------------
CMD ["/app/.venv/bin/python", "-m", "langflow", "run", "--host", "0.0.0.0", "--port", "7860"]
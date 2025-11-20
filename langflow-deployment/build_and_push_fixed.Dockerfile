FROM python:3.12-slim
 
WORKDIR /app
 
# Install OS dependencies needed for build

RUN apt-get update && apt-get install -y \

    nodejs npm git build-essential
 
# Copy Langflow source

COPY . /app
 
# ---------------------------

# Install frontend

# ---------------------------

WORKDIR /app/src/frontend

RUN npm install

RUN npm run build
 
# The build output goes to: /app/src/frontend/dist
 
# ---------------------------

# Move frontend build to backend path expected by Langflow

# ---------------------------

WORKDIR /app

RUN mkdir -p /app/src/backend/base/langflow/frontend \
&& cp -r /app/src/frontend/dist/* /app/src/backend/base/langflow/frontend/
 
# ---------------------------

# Backend (Python)

# ---------------------------

WORKDIR /app

RUN pip install uv

RUN uv sync --frozen --no-editable --extra postgresql
 
ENV PYTHONPATH=/app

ENV PORT=7860

ENV LANGFLOW_DATABASE_URL=sqlite:////app/langflow.db
 
CMD ["bash", "-c", "uv run langflow run --host 0.0.0.0 --port $PORT --backend-only"]

 
# ==============================

# BASE IMAGE

# ==============================

FROM python:3.12-slim
 
# Set working directory

WORKDIR /app
 
# ==============================

# SYSTEM DEPENDENCIES

# Needed for frontend + uv build

# ==============================

RUN apt-get update && apt-get install -y \

    git \

    build-essential \

    nodejs \

    npm \

    curl \
&& rm -rf /var/lib/apt/lists/*
 
# ==============================

# COPY PROJECT

# ==============================

COPY . /app
 
# ==============================

# FRONTEND BUILD (REQUIRED)

# Langflow uses Vite/React frontend

# ==============================

WORKDIR /app/src/frontend

RUN npm install

RUN npm run build
 
# ==============================

# COPY FRONTEND BUILD TO BACKEND

# Langflow expects this exact path:

# /app/src/backend/base/langflow/frontend

# ==============================

WORKDIR /app

RUN mkdir -p /app/src/backend/base/langflow/frontend && \

    cp -r /app/src/frontend/dist/* /app/src/backend/base/langflow/frontend/
 
# ==============================

# BACKEND SETUP USING UV

# ==============================

RUN pip install uv

RUN uv sync --frozen --no-install-project --no-editable --extra postgresql
 
# ==============================

# ENVIRONMENT VARIABLES

# ==============================

ENV PYTHONPATH=/app

ENV PORT=7860

ENV LANGFLOW_DATABASE_URL=sqlite:////app/langflow.db

ENV LANGFLOW_HOME=/app
 
# ==============================

# COMMAND TO START LANGFLOW

# Backend only (API mode)

# ==============================

CMD ["bash", "-c", "uv run langflow run --host 0.0.0.0 --port $PORT --backend-only"]

 
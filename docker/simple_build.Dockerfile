# syntax=docker/dockerfile:1

# Use the official Langflow image as base
FROM langflowai/langflow:latest

# Copy custom configuration if needed
# COPY custom-config.yml /app/

# Set environment variables
ENV LANGFLOW_HOST=0.0.0.0
ENV LANGFLOW_PORT=7860
ENV LANGFLOW_AUTO_LOGIN=true
ENV LANGFLOW_SUPERUSER=admin
ENV LANGFLOW_SUPERUSER_PASSWORD=admin123
ENV DO_NOT_TRACK=true
ENV LANGFLOW_CONFIG_DIR=/app/langflow

# Expose port
EXPOSE 7860

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:7860/health || exit 1

# Default command
CMD ["langflow", "run"]

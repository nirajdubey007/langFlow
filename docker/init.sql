-- PostgreSQL initialization script for Langflow
-- This script runs automatically when the PostgreSQL container is first created

-- Enable the pgvector extension for vector operations
CREATE EXTENSION IF NOT EXISTS vector;

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE langflow TO langflow;






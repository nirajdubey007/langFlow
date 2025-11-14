-- PostgreSQL initialization script for Langflow
-- Create necessary extensions and configurations

-- Enable the pgvector extension for vector operations
CREATE EXTENSION IF NOT EXISTS vector;

-- Create langflow database if it doesn't exist (though it should be created by POSTGRES_DB)
-- This is handled by the POSTGRES_DB environment variable in docker-compose.yml

-- Set up basic configurations
ALTER DATABASE langflow SET timezone = 'UTC';

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE langflow TO langflow;

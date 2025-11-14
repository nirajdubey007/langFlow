# Langflow Docker Setup

This directory contains a complete Docker setup for running Langflow with all required configurations.

## Files Created

### docker-compose.yml
A comprehensive Docker Compose configuration that includes:
- **Langflow Application**: Main web application running on port 7860
- **PostgreSQL Database**: Vector database with pgvector extension for AI operations
- **Health Checks**: Automatic health monitoring for both services
- **Volumes**: Persistent storage for data and logs
- **Networks**: Isolated network for secure communication

### .dockerignore
Optimized Docker ignore file to reduce build context size and improve build performance.

### docker/init.sql
PostgreSQL initialization script that:
- Enables the pgvector extension for vector operations
- Sets up proper database configuration
- Grants necessary permissions

## Environment Configuration

The setup includes the following environment variables:

### Langflow Application
- `LANGFLOW_HOST=0.0.0.0` - Bind to all interfaces
- `LANGFLOW_PORT=7860` - Application port
- `LANGFLOW_AUTO_LOGIN=true` - Enable auto-login for testing
- `LANGFLOW_SUPERUSER=admin` - Default superuser
- `LANGFLOW_SUPERUSER_PASSWORD=admin123` - Default password
- `LANGFLOW_DATABASE_URL=postgresql://langflow:langflow@postgres:5432/langflow` - Database connection
- `DO_NOT_TRACK=true` - Disable telemetry
- `LANGFLOW_CORS_ORIGINS=*` - Allow all origins for development

### PostgreSQL Database
- `POSTGRES_USER=langflow` - Database user
- `POSTGRES_PASSWORD=langflow` - Database password
- `POSTGRES_DB=langflow` - Database name

## Volumes

- `langflow-postgres` - PostgreSQL data persistence
- `langflow-data` - Langflow application data
- `langflow-logs` - Application logs

## Networks

- `langflow-network` - Isolated bridge network for secure inter-service communication

## Usage Instructions

### Prerequisites
- Docker Desktop installed and running
- At least 4GB free disk space for Docker images and containers
- Ports 7860 (Langflow) and 5432 (PostgreSQL) available

### Starting the Application

1. **Navigate to the project root directory:**
   ```bash
   cd /path/to/langflow
   ```

2. **Start the services:**
   ```bash
   docker-compose up -d
   ```

3. **Check service status:**
   ```bash
   docker-compose ps
   ```

4. **View logs:**
   ```bash
   docker-compose logs -f langflow
   ```

5. **Access Langflow:**
   Open your browser and go to: `http://localhost:7860`

### Stopping the Application

```bash
docker-compose down
```

### Resetting Data

To completely reset all data and start fresh:

```bash
docker-compose down -v  # Remove volumes
docker-compose up -d    # Start fresh
```

## Health Checks

The setup includes automatic health checks:
- **Langflow**: Checks `/health` endpoint every 30 seconds
- **PostgreSQL**: Uses `pg_isready` command for database availability

## Troubleshooting

### Common Issues

1. **Port conflicts:**
   - Ensure ports 7860 and 5432 are not in use
   - Modify `docker-compose.yml` to use different ports if needed

2. **Disk space issues:**
   - Docker requires significant disk space
   - Run `docker system prune -a` to clean up unused images

3. **Database connection issues:**
   - Check PostgreSQL logs: `docker-compose logs postgres`
   - Verify database is healthy: `docker-compose ps`

4. **Application startup issues:**
   - Check Langflow logs: `docker-compose logs langflow`
   - Ensure database is ready before Langflow starts

### Useful Commands

```bash
# View all running containers
docker ps

# Access container shell
docker exec -it langflow-app bash

# View resource usage
docker stats

# Clean up everything
docker-compose down -v --rmi all
```

## Security Considerations

⚠️ **This configuration is for development/testing only!**

For production deployment:
- Change default passwords
- Use environment-specific configuration files
- Implement proper authentication
- Configure TLS/SSL certificates
- Set up proper CORS policies
- Use managed database services
- Implement backup strategies

## Alternative Dockerfiles

The project includes several Dockerfile variations:

- `docker/build_and_push.Dockerfile` - Production build with all dependencies
- `docker/dev.Dockerfile` - Development build with hot reloading
- `Dockerfile.minimal` - Minimal build for testing (created for this setup)

## Testing the Setup

Once Docker has sufficient disk space, you can test the setup by:

1. Running: `docker-compose up -d`
2. Checking: `docker-compose ps` (should show both services healthy)
3. Accessing: `http://localhost:7860`
4. Creating a simple flow to verify functionality
5. Testing database persistence by stopping/starting containers

## Performance Optimization

- The setup uses PostgreSQL with pgvector for optimal AI operations
- Health checks prevent premature startup
- Proper dependency management ensures consistent builds
- Volume mounting provides data persistence

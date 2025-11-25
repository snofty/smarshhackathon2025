# Multi-MCP Server Setup Guide

## Overview

This setup allows you to run **multiple MCP servers** simultaneously, each with its own HTTP bridge on different ports. This is ideal for integrating multiple data sources (GitHub, Kibana, etc.) into n8n or other tools.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Compose Setup                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │  github-mcp      │◄────────│  github-bridge   │          │
│  │  (stdio)         │         │  (HTTP)          │          │
│  │                  │         │  Port: 3000      │◄─────────┼──► n8n
│  └──────────────────┘         └──────────────────┘          │
│                                                               │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │  kibana-mcp      │◄────────│  kibana-bridge   │          │
│  │  (stdio)         │         │  (HTTP)          │          │
│  │                  │         │  Port: 3001      │◄─────────┼──► n8n
│  └──────────────────┘         └──────────────────┘          │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Features

✅ **Multiple MCP Servers**: Run GitHub, Kibana, and more simultaneously  
✅ **Separate Ports**: Each bridge on its own port (3000, 3001, etc.)  
✅ **Independent Configuration**: Each server has its own credentials  
✅ **Reusable Bridge**: Same bridge code works for any stdio MCP server  
✅ **n8n Ready**: HTTP Streamable transport for easy integration  

## Quick Start

### 1. Prerequisites

- Docker and Docker Compose installed
- GitHub Personal Access Token
- Kibana server URL and credentials

### 2. Setup Configuration

```bash
# Copy the example environment file
cp .env.multi-mcp.example .env

# Edit with your credentials
nano .env
```

Required variables:
```bash
# Project name
COMPOSE_PROJECT_NAME=multi-mcp

# GitHub
GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxx...

# Kibana
KIBANA_URL=http://your-kibana:5601
KIBANA_USERNAME=your-username
KIBANA_PASSWORD=your-password
```

### 3. Update Repository Path

Edit `multi-mcp-docker-compose.yml` and update the workspace volume path:

```yaml
volumes:
  - /path/to/your/repository:/workspace:ro
```

### 4. Start Services

```bash
# Start all services
docker compose -f multi-mcp-docker-compose.yml up -d

# View logs
docker compose -f multi-mcp-docker-compose.yml logs -f

# Check status
docker compose -f multi-mcp-docker-compose.yml ps
```

### 5. Verify Setup

```bash
# Test GitHub bridge
curl http://localhost:3000/health
curl http://localhost:3000/tools | jq '.tools | length'

# Test Kibana bridge
curl http://localhost:3001/health
curl http://localhost:3001/tools | jq '.tools | length'
```

## Service Details

### GitHub MCP Server (Port 3000)

**Container**: `multi-mcp-github-mcp-1`  
**Bridge**: `multi-mcp-github-bridge-1`  
**Port**: 3000  
**Endpoints**:
- Health: `http://localhost:3000/health`
- Tools: `http://localhost:3000/tools`
- MCP Protocol: `http://localhost:3000/message`

**Available Tools**: 40+ GitHub tools (repositories, issues, PRs, code search, etc.)

### Kibana MCP Server (Port 3001)

**Container**: `multi-mcp-kibana-mcp-1`  
**Bridge**: `multi-mcp-kibana-bridge-1`  
**Port**: 3001  
**Endpoints**:
- Health: `http://localhost:3001/health`
- Tools: `http://localhost:3001/tools`
- MCP Protocol: `http://localhost:3001/message`

**Available Tools**: Kibana search, visualization, saved objects management, etc.

## n8n Integration

### Configure Multiple MCP Clients

In your n8n workflow, add multiple MCP Client nodes:

#### GitHub MCP Client

```
Name: GitHub MCP
Endpoint URL: http://localhost:3001/message
Transport: HTTP Streamable
```

(Or from n8n container: `http://host.docker.internal:3000/message`)

#### Kibana MCP Client

```
Name: Kibana MCP
Endpoint URL: http://localhost:3001/message
Transport: HTTP Streamable
```

(Or from n8n container: `http://host.docker.internal:3001/message`)

### AI Agent Configuration

Connect both MCP clients to your AI Agent node:

```
AI Agent
├── Tool: GitHub MCP Client
└── Tool: Kibana MCP Client
```

The agent can now use tools from both sources!

## Adding More MCP Servers

### Step 1: Add MCP Server Service

Add to `multi-mcp-docker-compose.yml`:

```yaml
  your-mcp:
    image: your-mcp-server-image
    container_name: ${COMPOSE_PROJECT_NAME:-multi-mcp}-your-mcp-1
    stdin_open: true
    tty: true
    environment:
      - YOUR_CONFIG=value
    command: ["stdio"]
    restart: unless-stopped
```

### Step 2: Create Bridge Directory

```bash
mkdir your-bridge
cp mcp-bridge/package.json your-bridge/
cp mcp-bridge/server.js your-bridge/
```

### Step 3: Add Bridge Service

```yaml
  your-bridge:
    image: node:20-alpine
    container_name: ${COMPOSE_PROJECT_NAME:-multi-mcp}-your-bridge-1
    working_dir: /app
    volumes:
      - ./your-bridge:/app
      - /var/run/docker.sock:/var/run/docker.sock
    ports:
      - "3002:3000"  # Next available port
    environment:
      - MCP_CONTAINER_NAME=your-mcp
      - COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME:-multi-mcp}
      - MCP_SERVER_COMMAND=/path/to/your-mcp-server
    command: sh -c "apk add --no-cache docker-cli && npm install && npm start"
    restart: unless-stopped
    depends_on:
      - your-mcp
```

### Step 4: Update Environment

Add credentials to `.env`:

```bash
YOUR_MCP_CONFIG=value
```

### Step 5: Restart

```bash
docker compose -f multi-mcp-docker-compose.yml up -d
```

## Management Commands

### Start/Stop Services

```bash
# Start all
docker compose -f multi-mcp-docker-compose.yml up -d

# Start specific service
docker compose -f multi-mcp-docker-compose.yml up -d github-bridge

# Stop all
docker compose -f multi-mcp-docker-compose.yml down

# Stop specific service
docker compose -f multi-mcp-docker-compose.yml stop kibana-bridge
```

### View Logs

```bash
# All services
docker compose -f multi-mcp-docker-compose.yml logs -f

# Specific service
docker compose -f multi-mcp-docker-compose.yml logs -f github-bridge

# Last 50 lines
docker compose -f multi-mcp-docker-compose.yml logs --tail=50 kibana-bridge
```

### Restart Services

```bash
# Restart all
docker compose -f multi-mcp-docker-compose.yml restart

# Restart specific
docker compose -f multi-mcp-docker-compose.yml restart github-bridge
```

### Check Status

```bash
# List containers
docker compose -f multi-mcp-docker-compose.yml ps

# Check resource usage
docker stats
```

## Troubleshooting

### Bridge Can't Connect to MCP Server

**Symptom**: `Error: No such container: multi-mcp-github-mcp-1`

**Solution**: Check container names match:

```bash
# List actual containers
docker ps --format "{{.Names}}"

# Check .env file
cat .env | grep COMPOSE_PROJECT_NAME

# Update if needed
docker compose -f multi-mcp-docker-compose.yml down
docker compose -f multi-mcp-docker-compose.yml up -d
```

### Port Already in Use

**Symptom**: `Error: port 3000 is already allocated`

**Solution**: Change the port mapping:

```yaml
ports:
  - "3002:3000"  # Use 3002 instead of 3000
```

### Kibana Authentication Fails

**Symptom**: `401 Unauthorized` or `403 Forbidden`

**Solution**: Verify credentials:

```bash
# Test Kibana connection
curl -u username:password http://your-kibana:5601/api/status

# Check environment variables
docker compose -f multi-mcp-docker-compose.yml exec kibana-mcp env | grep KIBANA
```

### MCP Server Not Starting

**Symptom**: Container exits immediately

**Solution**: Check logs:

```bash
# View container logs
docker compose -f multi-mcp-docker-compose.yml logs kibana-mcp

# Check if npm package installed correctly
docker compose -f multi-mcp-docker-compose.yml exec kibana-mcp which mcp-server-kibana
```

## Port Reference

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| GitHub Bridge | 3000 | http://localhost:3000 | GitHub MCP HTTP API |
| Kibana Bridge | 3001 | http://localhost:3001 | Kibana MCP HTTP API |
| Your Bridge | 3002+ | http://localhost:3002 | Additional MCP servers |

## Security Considerations

⚠️ **Important Security Notes**:

1. **Credentials**: Never commit `.env` file to version control
2. **Docker Socket**: Mounting `/var/run/docker.sock` gives containers Docker access
3. **Network**: Consider using Docker networks instead of host ports in production
4. **TLS**: Use HTTPS and proper certificates in production
5. **Authentication**: Add authentication layer for HTTP bridges in production

## Performance Tips

1. **Resource Limits**: Add resource constraints in docker-compose:
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '0.5'
         memory: 512M
   ```

2. **Logging**: Limit log size:
   ```yaml
   logging:
     driver: "json-file"
     options:
       max-size: "10m"
       max-file: "3"
   ```

3. **Health Checks**: Add health checks:
   ```yaml
   healthcheck:
     test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
     interval: 30s
     timeout: 10s
     retries: 3
   ```

## Example Use Cases

### 1. Code Analysis with Context

```
User: "Find the authentication code in our repo and check if there are any related errors in Kibana"

AI Agent:
1. Uses GitHub MCP → search_code for authentication
2. Uses Kibana MCP → search logs for errors
3. Correlates findings and reports
```

### 2. Incident Response

```
User: "There's an error in production. Find the code and recent deployments"

AI Agent:
1. Uses Kibana MCP → get error details
2. Uses GitHub MCP → find related code
3. Uses GitHub MCP → list recent commits/PRs
4. Provides comprehensive incident report
```

### 3. Documentation Generation

```
User: "Document our API endpoints with usage examples from logs"

AI Agent:
1. Uses GitHub MCP → get API code
2. Uses Kibana MCP → find usage patterns
3. Generates documentation with real examples
```

## Summary

✅ **Flexible**: Add any stdio-based MCP server  
✅ **Scalable**: Run multiple servers simultaneously  
✅ **Portable**: Works on any machine with Docker  
✅ **Integrated**: Ready for n8n and other tools  
✅ **Maintainable**: Reusable bridge architecture  

**You now have a complete multi-MCP server setup with separate HTTP bridges on different ports!** 🎉

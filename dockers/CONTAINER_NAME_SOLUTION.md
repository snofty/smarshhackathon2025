# Container Name Configuration - Solution

## Problem

The MCP bridge needs to communicate with the GitHub MCP container using `docker exec`. However, Docker Compose generates container names dynamically based on the directory name:

```
Format: <directory-name>-<service-name>-<instance-number>
```

Examples:
- In `/dockers` directory: `dockers-github-mcp-1`
- In `/my-project` directory: `my-project-github-mcp-1`
- In `/github-mcp-server` directory: `github-mcp-server-github-mcp-1`

Hardcoding the container name would break the setup on different machines or directories.

## Solution

Use **environment variables** to dynamically construct the container name at runtime.

### 1. Docker Compose Configuration

```yaml
services:
  mcp-bridge:
    environment:
      - MCP_CONTAINER_NAME=github-mcp
      - COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME:-dockers}
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock  # Required for docker exec
    command: sh -c "apk add --no-cache docker-cli && npm install && npm start"
```

### 2. Bridge Server Code

```javascript
// Initialize MCP client connection
async function initializeMCP() {
  try {
    console.log('Starting GitHub MCP Server...');
    
    // Get the actual container name dynamically
    const projectName = process.env.COMPOSE_PROJECT_NAME || 'dockers';
    const serviceName = process.env.MCP_CONTAINER_NAME || 'github-mcp';
    const containerName = `${projectName}-${serviceName}-1`;
    
    console.log(`Connecting to container: ${containerName}`);
    
    const transport = new StdioClientTransport({
      command: 'docker',
      args: ['exec', '-i', containerName, '/server/github-mcp-server', 'stdio'],
      env: process.env
    });
    
    // ... rest of initialization
  }
}
```

## How It Works

1. **COMPOSE_PROJECT_NAME**: Docker Compose automatically sets this based on the directory name
2. **MCP_CONTAINER_NAME**: We explicitly set this to the service name (`github-mcp`)
3. **Dynamic Construction**: The code builds the full container name at runtime
4. **Docker Socket**: The `/var/run/docker.sock` mount allows the bridge container to execute docker commands
5. **Docker CLI**: We install `docker-cli` in the Alpine container to run `docker exec`

## Benefits

✅ **Portable**: Works on any machine, any directory  
✅ **No Hardcoding**: Container names are discovered dynamically  
✅ **Flexible**: Can override `COMPOSE_PROJECT_NAME` if needed  
✅ **Maintainable**: Single source of truth for service names  

## Testing

```bash
# Check the container name being used
docker compose logs mcp-bridge | grep "Connecting to container"

# Output: Connecting to container: dockers-github-mcp-1
```

## Alternative Approaches Considered

### ❌ Approach 1: Use `docker compose exec`
```javascript
args: ['compose', 'exec', '-T', 'github-mcp', ...]
```
**Problem**: The bridge container doesn't have access to the compose file context.

### ❌ Approach 2: Hardcode container name
```javascript
const containerName = 'dockers-github-mcp-1';
```
**Problem**: Breaks when directory name changes.

### ❌ Approach 3: Network communication
**Problem**: GitHub MCP server only supports stdio, not network protocols.

### ✅ Approach 4: Dynamic container name (Current Solution)
**Advantages**: Portable, flexible, and works reliably across environments.

## Setup Script Integration

The `setup-github-mcp.sh` script automatically:
1. Creates the docker-compose.yml with correct environment variables
2. Generates the bridge server with dynamic container name logic
3. Sets appropriate defaults for `COMPOSE_PROJECT_NAME`

## Troubleshooting

### Container name mismatch
```bash
# Check actual container names
docker ps --format "{{.Names}}"

# Check what the bridge is trying to connect to
docker compose logs mcp-bridge | grep "Connecting to container"
```

### Override project name
```bash
# Set custom project name
export COMPOSE_PROJECT_NAME=my-custom-name
docker compose up -d
```

### Verify docker socket access
```bash
# Test from inside bridge container
docker exec dockers-mcp-bridge-1 docker ps
```

## Security Considerations

⚠️ **Docker Socket Access**: Mounting `/var/run/docker.sock` gives the container access to the Docker daemon. This is necessary for `docker exec` but should be used carefully in production environments.

**Mitigation**:
- Use read-only mounts where possible
- Limit container capabilities
- Consider using Docker-in-Docker alternatives for production
- Implement proper access controls

## Summary

This solution provides a **portable, maintainable way** to handle Docker container communication across different environments by:
- Using environment variables for configuration
- Dynamically constructing container names at runtime
- Leveraging Docker Compose's built-in project naming
- Providing sensible defaults with override capability

The setup script ensures this works out-of-the-box on any machine! 🎉

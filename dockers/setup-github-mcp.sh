#!/bin/bash

################################################################################
# GitHub MCP Server Setup Script
# 
# This script sets up the GitHub MCP Server with HTTP bridge for n8n integration
# on any machine with Docker installed.
#
# Usage:
#   ./setup-github-mcp.sh
#
# Requirements:
#   - Docker and Docker Compose installed
#   - GitHub Personal Access Token
################################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}ℹ ${NC}$1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Check if Docker is installed
check_docker() {
    print_header "Checking Prerequisites"
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        echo "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    print_success "Docker is installed"
    
    if ! command -v docker compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    print_success "Docker Compose is installed"
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi
    print_success "Docker daemon is running"
}

# Get GitHub token from user
get_github_token() {
    print_header "GitHub Personal Access Token Setup"
    
    echo "You need a GitHub Personal Access Token to use the GitHub MCP Server."
    echo ""
    echo "To create one:"
    echo "  1. Visit: https://github.com/settings/personal-access-tokens/new"
    echo "  2. Grant permissions: repo, read:org, read:user"
    echo "  3. Copy the generated token"
    echo ""
    
    # Check if token already exists in .env
    if [ -f ".env" ] && grep -q "GITHUB_PERSONAL_ACCESS_TOKEN=" ".env"; then
        EXISTING_TOKEN=$(grep "GITHUB_PERSONAL_ACCESS_TOKEN=" .env | cut -d'=' -f2)
        if [ -n "$EXISTING_TOKEN" ]; then
            print_info "Found existing token in .env file"
            read -p "Do you want to use the existing token? (y/n): " use_existing
            if [[ $use_existing =~ ^[Yy]$ ]]; then
                GITHUB_TOKEN="$EXISTING_TOKEN"
                print_success "Using existing token"
                return
            fi
        fi
    fi
    
    read -sp "Enter your GitHub Personal Access Token: " GITHUB_TOKEN
    echo ""
    
    if [ -z "$GITHUB_TOKEN" ]; then
        print_error "Token cannot be empty"
        exit 1
    fi
    
    print_success "Token received"
}

# Get repository path
get_repo_path() {
    print_header "Repository Path Configuration"
    
    echo "Enter the absolute path to your local repository that you want to expose via MCP."
    echo "Example: /Users/username/projects/my-repo"
    echo ""
    
    # Try to detect current git repository
    if git rev-parse --show-toplevel &> /dev/null; then
        DETECTED_REPO=$(git rev-parse --show-toplevel)
        print_info "Detected git repository: $DETECTED_REPO"
        read -p "Use this path? (y/n): " use_detected
        if [[ $use_detected =~ ^[Yy]$ ]]; then
            REPO_PATH="$DETECTED_REPO"
            print_success "Using detected repository path"
            return
        fi
    fi
    
    read -p "Repository path: " REPO_PATH
    
    if [ -z "$REPO_PATH" ]; then
        print_error "Repository path cannot be empty"
        exit 1
    fi
    
    # Expand ~ to home directory
    REPO_PATH="${REPO_PATH/#\~/$HOME}"
    
    if [ ! -d "$REPO_PATH" ]; then
        print_error "Directory does not exist: $REPO_PATH"
        exit 1
    fi
    
    print_success "Repository path: $REPO_PATH"
}

# Get project name for Docker Compose
get_project_name() {
    print_header "Project Name Configuration"
    
    echo "Choose a project name for your Docker Compose setup."
    echo "This will be used as a prefix for container names."
    echo ""
    
    # Suggest name based on current directory
    CURRENT_DIR=$(basename "$PWD")
    DEFAULT_PROJECT_NAME="${CURRENT_DIR}"
    
    print_info "Suggested name: $DEFAULT_PROJECT_NAME"
    echo "Examples:"
    echo "  - 'my-project' → containers: my-project-github-mcp-1, my-project-mcp-bridge-1"
    echo "  - 'github-mcp-server' → containers: github-mcp-server-github-mcp-1, etc."
    echo ""
    
    read -p "Project name (press Enter for '$DEFAULT_PROJECT_NAME'): " PROJECT_NAME
    
    if [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME="$DEFAULT_PROJECT_NAME"
    fi
    
    # Sanitize project name (remove special characters, convert to lowercase)
    PROJECT_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]/-/g')
    
    print_success "Project name: $PROJECT_NAME"
    print_info "Container names will be: ${PROJECT_NAME}-github-mcp-1, ${PROJECT_NAME}-mcp-bridge-1"
}

# Create directory structure
create_directories() {
    print_header "Creating Directory Structure"
    
    mkdir -p mcp-bridge
    print_success "Created mcp-bridge directory"
}

# Create .env file
create_env_file() {
    print_header "Creating Environment Configuration"
    
    cat > .env << EOF
GITHUB_PERSONAL_ACCESS_TOKEN=$GITHUB_TOKEN
COMPOSE_PROJECT_NAME=$PROJECT_NAME
EOF
    
    chmod 600 .env
    print_success "Created .env file"
    print_info "Project name: $PROJECT_NAME"
    
    # Create .gitignore if it doesn't exist
    if [ ! -f ".gitignore" ]; then
        cat > .gitignore << EOF
.env
node_modules/
*.log
EOF
        print_success "Created .gitignore file"
    else
        # Add .env to existing .gitignore if not already there
        if ! grep -q "^\.env$" .gitignore 2>/dev/null; then
            echo ".env" >> .gitignore
            print_success "Added .env to .gitignore"
        fi
    fi
}

# Create docker-compose.yml
create_docker_compose() {
    print_header "Creating Docker Compose Configuration"
    
    cat > docker-compose.yml << 'EOF'
# ============================================================================
# GitHub MCP Server with HTTP Bridge
# ============================================================================
#
# This setup provides:
# 1. GitHub MCP Server - Accesses GitHub repositories via API
# 2. MCP-to-HTTP Bridge - Exposes MCP over HTTP for n8n integration
#
# USAGE:
#   docker compose up -d
#
# N8N INTEGRATION:
# For n8n MCP Client node (HTTP Streamable transport):
#   URL: http://localhost:3000/message (or http://host.docker.internal:3000/message from n8n container)
#   Transport: HTTP Streamable
#
# ENDPOINTS:
#   GET  /health           - Health check
#   POST /message          - MCP protocol endpoint (for n8n)
#   GET  /tools            - List available tools
#   POST /tools/:toolName  - Call a specific tool
#   GET  /resources        - List resources
#
# ============================================================================

services:
  github-mcp:
    image: ghcr.io/github/github-mcp-server:latest
    stdin_open: true
    tty: true
    environment:
      - GITHUB_PERSONAL_ACCESS_TOKEN=${GITHUB_PERSONAL_ACCESS_TOKEN}
    volumes:
      - REPO_PATH_PLACEHOLDER:/workspace:ro
    working_dir: /workspace
    command: ["stdio"]
    restart: unless-stopped

  mcp-bridge:
    image: node:20-alpine
    working_dir: /app
    volumes:
      - ./mcp-bridge:/app
      - /var/run/docker.sock:/var/run/docker.sock
      - REPO_PATH_PLACEHOLDER:/workspace:ro
    ports:
      - "3000:3000"
    environment:
      - GITHUB_PERSONAL_ACCESS_TOKEN=${GITHUB_PERSONAL_ACCESS_TOKEN}
      - MCP_CONTAINER_NAME=github-mcp
      - COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME}
    command: sh -c "apk add --no-cache docker-cli && npm install && npm start"
    restart: unless-stopped
    depends_on:
      - github-mcp
EOF
    
    # Replace placeholder with actual repo path
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|REPO_PATH_PLACEHOLDER|$REPO_PATH|g" docker-compose.yml
    else
        sed -i "s|REPO_PATH_PLACEHOLDER|$REPO_PATH|g" docker-compose.yml
    fi
    
    print_success "Created docker-compose.yml"
}

# Create bridge server files
create_bridge_server() {
    print_header "Creating MCP Bridge Server"
    
    # Create package.json
    cat > mcp-bridge/package.json << 'EOF'
{
  "name": "mcp-http-bridge",
  "version": "1.0.0",
  "type": "module",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.4",
    "express": "^4.21.1"
  }
}
EOF
    print_success "Created package.json"
    
    # Create server.js
    cat > mcp-bridge/server.js << 'EOF'
/**
 * MCP-to-HTTP Bridge Server
 * Exposes MCP stdio server over HTTP for n8n integration
 */

import express from 'express';
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';

const app = express();

// Enable CORS for n8n
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

app.use(express.json());

let mcpClient = null;

// Initialize MCP client connection
async function initializeMCP() {
  try {
    console.log('Starting GitHub MCP Server...');
    
    // Get the actual container name dynamically
    // COMPOSE_PROJECT_NAME is set in .env file or defaults to directory name
    const projectName = process.env.COMPOSE_PROJECT_NAME;
    const serviceName = process.env.MCP_CONTAINER_NAME || 'github-mcp';
    
    if (!projectName) {
      throw new Error('COMPOSE_PROJECT_NAME environment variable is not set');
    }
    
    const containerName = \`\${projectName}-\${serviceName}-1\`;
    
    console.log(\`Connecting to container: \${containerName}\`);
    
    const transport = new StdioClientTransport({
      command: 'docker',
      args: ['exec', '-i', containerName, '/server/github-mcp-server', 'stdio'],
      env: process.env
    });

    mcpClient = new Client({
      name: 'mcp-http-bridge',
      version: '1.0.0'
    }, {
      capabilities: {}
    });

    await mcpClient.connect(transport);
    console.log('MCP client connected successfully');
  } catch (error) {
    console.error('Failed to initialize MCP:', error);
    throw error;
  }
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    mcpConnected: mcpClient !== null,
    timestamp: new Date().toISOString()
  });
});

// List available tools
app.get('/tools', async (req, res) => {
  try {
    if (!mcpClient) {
      return res.status(503).json({ error: 'MCP client not connected' });
    }

    const tools = await mcpClient.listTools();
    res.json(tools);
  } catch (error) {
    console.error('Error listing tools:', error);
    res.status(500).json({ error: error.message });
  }
});

// Call a specific tool
app.post('/tools/:toolName', async (req, res) => {
  try {
    if (!mcpClient) {
      return res.status(503).json({ error: 'MCP client not connected' });
    }

    const { toolName } = req.params;
    const { arguments: toolArgs } = req.body;

    const result = await mcpClient.callTool({
      name: toolName,
      arguments: toolArgs || {}
    });

    res.json(result);
  } catch (error) {
    console.error('Error calling tool:', error);
    res.status(500).json({ error: error.message });
  }
});

// List resources
app.get('/resources', async (req, res) => {
  try {
    if (!mcpClient) {
      return res.status(503).json({ error: 'MCP client not connected' });
    }

    const resources = await mcpClient.listResources();
    res.json(resources);
  } catch (error) {
    console.error('Error listing resources:', error);
    res.status(500).json({ error: error.message });
  }
});

// MCP HTTP Streamable endpoint for n8n
app.post('/message', async (req, res) => {
  try {
    if (!mcpClient) {
      return res.status(503).json({ 
        jsonrpc: '2.0',
        error: { code: -32000, message: 'MCP client not connected' },
        id: req.body.id 
      });
    }

    const { jsonrpc, method, params, id } = req.body;

    let result;
    switch (method) {
      case 'initialize':
        result = {
          protocolVersion: '2024-11-05',
          capabilities: {
            tools: {},
            resources: {}
          },
          serverInfo: {
            name: 'github-mcp-bridge',
            version: '1.0.0'
          }
        };
        break;
      
      case 'tools/list':
        result = await mcpClient.listTools();
        break;
      
      case 'tools/call':
        result = await mcpClient.callTool(params);
        break;
      
      case 'resources/list':
        result = await mcpClient.listResources();
        break;
      
      case 'resources/read':
        result = await mcpClient.readResource(params);
        break;
      
      case 'ping':
        result = {};
        break;
      
      default:
        return res.json({
          jsonrpc: '2.0',
          error: { code: -32601, message: `Method not found: ${method}` },
          id
        });
    }

    res.json({
      jsonrpc: '2.0',
      result,
      id
    });
  } catch (error) {
    console.error('MCP protocol error:', error);
    res.json({
      jsonrpc: '2.0',
      error: { code: -32000, message: error.message },
      id: req.body.id
    });
  }
});

// SSE endpoint for streaming
app.get('/sse', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.setHeader('Access-Control-Allow-Origin', '*');
  
  res.write('event: connected\n');
  res.write('data: {"status":"connected"}\n\n');
  
  const keepAlive = setInterval(() => {
    res.write(':keepalive\n\n');
  }, 30000);
  
  req.on('close', () => {
    clearInterval(keepAlive);
  });
});

// Read a resource
app.get('/resources/:uri', async (req, res) => {
  try {
    if (!mcpClient) {
      return res.status(503).json({ error: 'MCP client not connected' });
    }

    const { uri } = req.params;
    const resource = await mcpClient.readResource({ uri });
    res.json(resource);
  } catch (error) {
    console.error('Error reading resource:', error);
    res.status(500).json({ error: error.message });
  }
});

// Start server
const PORT = process.env.PORT || 3000;

async function start() {
  try {
    await initializeMCP();
    
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`MCP HTTP Bridge listening on http://0.0.0.0:${PORT}`);
      console.log(`Available endpoints:`);
      console.log(`  GET  /health           - Health check`);
      console.log(`  GET  /tools            - List available tools`);
      console.log(`  POST /tools/:toolName  - Call a tool`);
      console.log(`  GET  /resources        - List available resources`);
      console.log(`  GET  /resources/:uri   - Read a resource`);
      console.log(`  POST /message          - MCP protocol endpoint (for n8n)`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('Shutting down...');
  if (mcpClient) {
    await mcpClient.close();
  }
  process.exit(0);
});

start();
EOF
    print_success "Created server.js"
    
    # Create README
    cat > mcp-bridge/README.md << 'EOF'
# MCP HTTP Bridge

Exposes the GitHub MCP Server over HTTP for integration with n8n and other HTTP-based tools.

## n8n MCP Client Configuration

For n8n's MCP client node with **HTTP Streamable** transport:

- **URL**: `http://localhost:3000/message` (or `http://host.docker.internal:3000/message` from n8n container)
- **Transport**: HTTP Streamable

## Endpoints

### Health Check
```bash
GET http://localhost:3000/health
```

### List Tools
```bash
GET http://localhost:3000/tools
```

### Call a Tool
```bash
POST http://localhost:3000/tools/search_code
Content-Type: application/json

{
  "arguments": {
    "query": "function repo:owner/repo-name",
    "perPage": 10
  }
}
```

### MCP Protocol (for n8n)
```bash
POST http://localhost:3000/message
Content-Type: application/json

{
  "jsonrpc": "2.0",
  "method": "tools/list",
  "params": {},
  "id": 1
}
```

## Available GitHub MCP Tools

- `search_code` - Search code across repositories
- `get_file_contents` - Read file contents
- `list_commits` - List commits
- `create_issue` - Create GitHub issue
- `create_pull_request` - Create pull request
- And many more...
EOF
    print_success "Created README.md"
}

# Start the services
start_services() {
    print_header "Starting Services"
    
    print_info "Pulling Docker images..."
    docker compose pull
    
    print_info "Starting containers..."
    docker compose up -d
    
    print_info "Waiting for services to be ready..."
    sleep 5
    
    # Check if services are running
    if docker compose ps | grep -q "Up"; then
        print_success "Services started successfully"
    else
        print_error "Failed to start services"
        docker compose logs
        exit 1
    fi
}

# Test the setup
test_setup() {
    print_header "Testing Setup"
    
    print_info "Testing health endpoint..."
    if curl -s http://localhost:3000/health | grep -q "ok"; then
        print_success "Health check passed"
    else
        print_warning "Health check failed - services may still be starting"
    fi
    
    print_info "Testing tools endpoint..."
    if curl -s http://localhost:3000/tools | grep -q "tools"; then
        print_success "Tools endpoint working"
    else
        print_warning "Tools endpoint not ready yet"
    fi
}

# Print final instructions
print_final_instructions() {
    print_header "Setup Complete!"
    
    echo ""
    echo -e "${GREEN}✓ GitHub MCP Server is running!${NC}"
    echo ""
    echo "Services:"
    echo "  • GitHub MCP Server: Running in container"
    echo "  • HTTP Bridge: http://localhost:3000"
    echo ""
    echo "n8n Configuration:"
    echo "  • URL: http://localhost:3000/message"
    echo "  • URL (from n8n container): http://host.docker.internal:3000/message"
    echo "  • Transport: HTTP Streamable"
    echo ""
    echo "Useful Commands:"
    echo "  • View logs:    docker compose logs -f"
    echo "  • Stop:         docker compose down"
    echo "  • Restart:      docker compose restart"
    echo "  • Health check: curl http://localhost:3000/health"
    echo "  • List tools:   curl http://localhost:3000/tools"
    echo ""
    echo "Documentation:"
    echo "  • Bridge README: ./mcp-bridge/README.md"
    echo "  • Docker Compose: ./docker-compose.yml"
    echo ""
}

# Cleanup on error
cleanup_on_error() {
    print_error "Setup failed. Cleaning up..."
    if [ -f "docker-compose.yml" ]; then
        docker compose down 2>/dev/null || true
    fi
}

# Set trap for cleanup
trap cleanup_on_error ERR

# Check for existing setup
check_existing_setup() {
    if [ -f "docker-compose.yml" ] && [ -d "mcp-bridge" ]; then
        print_warning "Existing setup detected!"
        echo "Found:"
        echo "  - docker-compose.yml"
        echo "  - mcp-bridge/"
        echo ""
        read -p "Do you want to overwrite the existing setup? (y/n): " overwrite
        if [[ ! $overwrite =~ ^[Yy]$ ]]; then
            print_info "Setup cancelled. Existing files preserved."
            exit 0
        fi
        print_warning "Existing setup will be overwritten"
    fi
}

# Main execution
main() {
    print_header "GitHub MCP Server Setup"
    
    check_existing_setup
    check_docker
    get_github_token
    get_repo_path
    get_project_name
    create_directories
    create_env_file
    create_docker_compose
    create_bridge_server
    start_services
    test_setup
    print_final_instructions
}

# Run main function
main

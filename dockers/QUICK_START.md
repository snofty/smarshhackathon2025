# GitHub MCP Server - Quick Start Guide

This guide helps you set up the GitHub MCP Server with HTTP bridge on any machine.

## Prerequisites

- **Docker** and **Docker Compose** installed
- **GitHub Personal Access Token** with `repo` permissions
- A local Git repository you want to expose

## One-Command Setup

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/dockers/setup-github-mcp.sh | bash
```

Or download and run locally:

```bash
# Download the script
wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/dockers/setup-github-mcp.sh

# Make it executable
chmod +x setup-github-mcp.sh

# Run it
./setup-github-mcp.sh
```

## Manual Setup

If you prefer to set up manually:

### 1. Create Directory Structure

```bash
mkdir github-mcp-server
cd github-mcp-server
mkdir mcp-bridge
```

### 2. Create `.env` File

```bash
cat > .env << 'EOF'
GITHUB_PERSONAL_ACCESS_TOKEN=your_token_here
EOF
```

Replace `your_token_here` with your actual GitHub token.

### 3. Download Setup Script

```bash
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/dockers/setup-github-mcp.sh
chmod +x setup-github-mcp.sh
./setup-github-mcp.sh
```

## What the Script Does

1. ✓ Checks Docker installation
2. ✓ Prompts for GitHub Personal Access Token
3. ✓ Asks for repository path to expose
4. ✓ Creates all necessary configuration files
5. ✓ Sets up MCP bridge server
6. ✓ Starts Docker containers
7. ✓ Tests the setup

## After Setup

### Access the MCP Server

- **Health Check**: http://localhost:3000/health
- **List Tools**: http://localhost:3000/tools
- **MCP Endpoint**: http://localhost:3000/message

### n8n Integration

Configure your n8n MCP Client node:

**If n8n is on the same machine:**
```
URL: http://localhost:3000/message
Transport: HTTP Streamable
```

**If n8n is in Docker:**
```
URL: http://host.docker.internal:3000/message
Transport: HTTP Streamable
```

**If n8n is on a different machine:**
```
URL: http://YOUR_SERVER_IP:3000/message
Transport: HTTP Streamable
```

### Test the Setup

```bash
# Health check
curl http://localhost:3000/health

# List available tools
curl http://localhost:3000/tools | jq

# Search code
curl -X POST http://localhost:3000/tools/search_code \
  -H "Content-Type: application/json" \
  -d '{
    "arguments": {
      "query": "function language:JavaScript",
      "perPage": 5
    }
  }' | jq
```

## Managing the Server

### View Logs
```bash
docker compose logs -f
```

### Stop the Server
```bash
docker compose down
```

### Restart the Server
```bash
docker compose restart
```

### Update Configuration
Edit `.env` or `docker-compose.yml`, then:
```bash
docker compose up -d
```

## Troubleshooting

### Port 3000 Already in Use
Edit `docker-compose.yml` and change the port mapping:
```yaml
ports:
  - "3001:3000"  # Use port 3001 instead
```

### GitHub Token Issues
1. Verify token has correct permissions
2. Check token hasn't expired
3. Update `.env` file with new token
4. Restart: `docker compose restart`

### Connection Issues from n8n
- If n8n is in Docker, use `http://host.docker.internal:3000/message`
- If on different machine, ensure port 3000 is accessible
- Check firewall settings

### View Detailed Logs
```bash
# All logs
docker compose logs

# Just bridge logs
docker compose logs mcp-bridge

# Follow logs in real-time
docker compose logs -f mcp-bridge
```

## Available GitHub MCP Tools

The server provides these tools:

- **search_code** - Search code across repositories
- **get_file_contents** - Read file contents
- **list_commits** - List repository commits
- **get_commit** - Get specific commit details
- **create_issue** - Create GitHub issue
- **create_pull_request** - Create pull request
- **list_issues** - List repository issues
- **update_issue** - Update an issue
- **list_pull_requests** - List pull requests
- **get_pull_request** - Get PR details
- **And more...**

## Security Notes

- The `.env` file contains your GitHub token - keep it secure
- Never commit `.env` to version control
- Use read-only repository mounts when possible
- Restrict network access to port 3000 if needed

## Support

For issues or questions:
- Check logs: `docker compose logs`
- Verify Docker is running: `docker info`
- Test endpoint: `curl http://localhost:3000/health`
- Review documentation in `mcp-bridge/README.md`

## Uninstall

```bash
# Stop and remove containers
docker compose down

# Remove all files
cd ..
rm -rf github-mcp-server
```

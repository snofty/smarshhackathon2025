# Custom Project Name Configuration

## Overview

You can now choose your own project name for the GitHub MCP setup. This name will be used as a prefix for all Docker container names.

## How It Works

### During Setup Script

When you run `./setup-github-mcp.sh`, you'll be prompted:

```
═══════════════════════════════════════════════════════════
  Project Name Configuration
═══════════════════════════════════════════════════════════

Choose a project name for your Docker Compose setup.
This will be used as a prefix for container names.

Suggested name: dockers
Examples:
  - 'my-project' → containers: my-project-github-mcp-1, my-project-mcp-bridge-1
  - 'github-mcp-server' → containers: github-mcp-server-github-mcp-1, etc.

Project name (press Enter for 'dockers'): 
```

### What Happens

1. **Default**: If you press Enter, it uses the current directory name
2. **Custom**: Enter any name you want (e.g., `my-mcp-setup`)
3. **Sanitization**: The name is automatically:
   - Converted to lowercase
   - Special characters replaced with hyphens
   - Made Docker-compatible

### Examples

| Input | Sanitized | Container Names |
|-------|-----------|-----------------|
| `My Project` | `my-project` | `my-project-github-mcp-1`, `my-project-mcp-bridge-1` |
| `GitHub_MCP` | `github-mcp` | `github-mcp-github-mcp-1`, `github-mcp-mcp-bridge-1` |
| `app123` | `app123` | `app123-github-mcp-1`, `app123-mcp-bridge-1` |

## Configuration Files

### .env File

The project name is stored in `.env`:

```bash
GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxx...
COMPOSE_PROJECT_NAME=my-project
```

### docker-compose.yml

The environment variable is passed to the bridge:

```yaml
mcp-bridge:
  environment:
    - COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME}
```

### Bridge Server

The server dynamically constructs the container name:

```javascript
const projectName = process.env.COMPOSE_PROJECT_NAME;
const serviceName = process.env.MCP_CONTAINER_NAME || 'github-mcp';
const containerName = `${projectName}-${serviceName}-1`;

console.log(`Connecting to container: ${containerName}`);
// Output: Connecting to container: my-project-github-mcp-1
```

## Manual Configuration

### Option 1: Edit .env File

```bash
# Edit the .env file
nano .env

# Change the project name
COMPOSE_PROJECT_NAME=my-custom-name

# Restart services
docker compose down
docker compose up -d
```

### Option 2: Environment Variable

```bash
# Set for current session
export COMPOSE_PROJECT_NAME=my-custom-name

# Start services
docker compose up -d
```

### Option 3: Command Line

```bash
# Use -p flag with docker compose
docker compose -p my-custom-name up -d
```

## Verification

Check your container names:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

Output:
```
NAMES                          STATUS
my-project-mcp-bridge-1       Up 5 minutes
my-project-github-mcp-1       Up 5 minutes
```

Check what the bridge is connecting to:

```bash
docker compose logs mcp-bridge | grep "Connecting to container"
```

Output:
```
mcp-bridge-1  | Connecting to container: my-project-github-mcp-1
```

## Benefits

✅ **Multiple Setups**: Run multiple MCP setups on the same machine with different names  
✅ **Clear Naming**: Use descriptive names for different projects  
✅ **No Conflicts**: Avoid container name collisions  
✅ **Easy Management**: Identify containers by project name  

## Use Cases

### Multiple Repositories

```bash
# Setup 1: Frontend repo
cd ~/projects/frontend-mcp
./setup-github-mcp.sh
# Choose name: frontend-mcp

# Setup 2: Backend repo
cd ~/projects/backend-mcp
./setup-github-mcp.sh
# Choose name: backend-mcp
```

Result:
```
frontend-mcp-github-mcp-1
frontend-mcp-mcp-bridge-1
backend-mcp-github-mcp-1
backend-mcp-mcp-bridge-1
```

### Different Ports

```bash
# Setup 1: Port 3000
COMPOSE_PROJECT_NAME=mcp-dev docker compose up -d

# Setup 2: Port 3001 (edit docker-compose.yml first)
COMPOSE_PROJECT_NAME=mcp-staging docker compose up -d
```

## Troubleshooting

### Container Not Found

If you see:
```
Error: No such container: dockers-github-mcp-1
```

**Solution**: Check your `.env` file has the correct `COMPOSE_PROJECT_NAME`

```bash
# Check current value
cat .env | grep COMPOSE_PROJECT_NAME

# List actual containers
docker ps --format "{{.Names}}"

# Update .env to match
echo "COMPOSE_PROJECT_NAME=actual-name" >> .env
```

### Bridge Can't Connect

If the bridge logs show:
```
Error: COMPOSE_PROJECT_NAME environment variable is not set
```

**Solution**: Ensure `.env` file exists and is loaded

```bash
# Verify .env exists
ls -la .env

# Restart with explicit env file
docker compose --env-file .env up -d
```

### Name Conflicts

If you get:
```
Error: container name already in use
```

**Solution**: Choose a different project name or stop existing containers

```bash
# Stop existing setup
docker compose -p old-name down

# Start with new name
export COMPOSE_PROJECT_NAME=new-name
docker compose up -d
```

## Best Practices

1. **Use Descriptive Names**: Choose names that clearly identify the project
2. **Keep It Short**: Shorter names = easier to type and read
3. **Use Hyphens**: Separate words with hyphens (e.g., `my-project`)
4. **Avoid Special Characters**: Stick to letters, numbers, and hyphens
5. **Document Your Choice**: Note the project name in your README

## Summary

Custom project names provide flexibility and clarity when managing multiple MCP setups. The setup script makes it easy to choose a name, and the configuration is automatically handled throughout the system.

**Default behavior**: Uses current directory name  
**Custom behavior**: Prompts during setup  
**Manual override**: Edit `.env` file anytime  

🎯 **Result**: Clean, organized, and conflict-free container naming!

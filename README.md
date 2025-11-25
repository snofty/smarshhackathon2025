# SMF Hackathon 2025 - n8n Production Alert Analyzer

AI-powered production alert analysis system using n8n, MCP servers, and OpenAI GPT-4o-mini.

## Overview

This project provides an intelligent alert analysis workflow that:
- 🔍 **Monitors** Slack channels for production alerts
- 🤖 **Analyzes** alerts using AI with context from GitHub code and Kibana logs
- 📊 **Provides** root cause analysis and actionable recommendations
- 🔗 **Integrates** multiple data sources via MCP (Model Context Protocol) servers

## Architecture

```
┌─────────────┐      ┌──────────────┐      ┌─────────────────┐
│   Slack     │─────▶│   n8n        │─────▶│   OpenAI        │
│   Alerts    │      │   Workflow   │      │   GPT-4o-mini   │
└─────────────┘      └──────┬───────┘      └─────────────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
         ┌──────▼──────┐         ┌─────▼──────┐
         │  GitHub MCP │         │ Kibana MCP │
         │  (Port 3000)│         │ (Port 3001)│
         └─────────────┘         └────────────┘
```

## Components

### 1. n8n Workflow
**Location**: `n8n-workflow/`

- **Production Alert Analyzer** - Enhanced workflow with AI-powered analysis
- **Slack Integration** - Monitors alerts and posts responses
- **AI Agent** - Routes by severity (CRITICAL vs HIGH/MEDIUM)
- **Code Context** - Optionally includes relevant code snippets

**Features**:
- ✅ Alert parsing and structured data extraction
- ✅ Severity-based routing (different analysis depth)
- ✅ Immediate acknowledgment responses
- ✅ Threaded Slack replies
- ✅ Metrics logging

📖 **Documentation**: See [`n8n-workflow/WORKFLOW_GUIDE.md`](n8n-workflow/WORKFLOW_GUIDE.md)

### 2. MCP Servers
**Location**: `dockers/`

Multi-MCP server setup with HTTP bridges for n8n integration:

#### GitHub MCP Server (Port 3000)
- Code search across repositories
- File contents retrieval
- Commit history and PR management
- 40+ GitHub tools available

#### Kibana MCP Server (Port 3001)
- Log search and analysis
- Visualization management
- Saved objects access
- Real-time error tracking

📖 **Documentation**: 
- [`dockers/MULTI_MCP_SETUP.md`](dockers/MULTI_MCP_SETUP.md) - Complete setup guide
- [`dockers/QUICK_START.md`](dockers/QUICK_START.md) - Quick start guide

### 3. Sample Application
**Location**: `sample-app/`

Spring Boot Order Service that simulates realistic production failures:
- Database timeouts and connection pool exhaustion
- Payment gateway failures
- Inventory service unavailability
- High error rates and memory issues

### 4. Sample Logs
**Location**: `sample-logs/`

15 realistic log entries for testing:
- Elasticsearch/Kibana import ready
- Matches alert scenarios
- Includes stack traces with code references
- Structured JSON format

📖 **Documentation**: [`sample-logs/README.md`](sample-logs/README.md)

### 5. Sample Alerts
**Location**: `sample-alerts/`

10 pre-formatted Slack alerts covering:
- Database timeouts (CRITICAL)
- Payment gateway failures (HIGH)
- Inventory issues (MEDIUM)
- High error rates (CRITICAL)
- Memory and performance issues

## Quick Start

### Prerequisites

- Docker and Docker Compose
- GitHub Personal Access Token
- Kibana server access (URL, username, password)
- n8n instance (cloud or self-hosted)
- OpenAI API key

### 1. Setup MCP Servers

```bash
cd dockers

# Copy and configure environment
cp .env.multi-mcp.example .env
nano .env  # Add your credentials

# Update repository path in multi-mcp-docker-compose.yml
# Edit the volumes section to point to your repo

# Start services
docker compose -f multi-mcp-docker-compose.yml up -d

# Verify
curl http://localhost:3000/health  # GitHub MCP
curl http://localhost:3001/health  # Kibana MCP
```

### 2. Import Logs to Kibana

```bash
cd sample-logs

# Generate bulk import file
node convert-to-bulk.js

# Import to Elasticsearch (replace with your details)
curl -X POST "https://YOUR_KIBANA_URL:9200/_bulk" \
  -H "Content-Type: application/x-ndjson" \
  -H "Authorization: ApiKey YOUR_API_KEY" \
  --data-binary @kibana-bulk-import.ndjson

# Create index pattern in Kibana UI: logs-order-service-*
```

### 3. Import n8n Workflow

1. Open n8n UI
2. Go to **Workflows** → **Import from File**
3. Select: `n8n-workflow/production-alert-analyzer.json`
4. Configure credentials:
   - **Slack API**: Add your Slack workspace credentials
   - **OpenAI API**: Add your OpenAI API key
5. Configure MCP clients:
   - **GitHub MCP**: `http://localhost:3000/message` (or `http://host.docker.internal:3000/message` if n8n in Docker)
   - **Kibana MCP**: `http://localhost:3001/message` (or `http://host.docker.internal:3001/message` if n8n in Docker)
6. Update channel IDs for your Slack workspace
7. Activate workflow

### 4. Test the System

```bash
# Option 1: Start sample application
cd sample-app
mvn clean install
mvn spring-boot:run

# Generate traffic
cd ../sample-alerts
./test-workflow.sh

# Option 2: Post sample alert to Slack
# Copy any alert from sample-alerts/sample-slack-alerts.md
# Paste into your #mcp-testing channel
```

## Usage

### Testing with Sample Alerts

1. Open Slack and navigate to your configured input channel (e.g., `#mcp-testing`)
2. Copy an alert from `sample-alerts/sample-slack-alerts.md`
3. Paste the alert into the channel
4. Wait 1-2 seconds for acknowledgment
5. Check output channel (e.g., `#n8n-output`) for AI analysis (5-10 seconds)

### Posting Datadog Alerts to Slack

Use the Python script to post Datadog alert configurations to Slack:

```bash
cd sample-alerts

# List all available alerts
python post_alerts_to_slack.py --list

# Post specific alerts by index
python post_alerts_to_slack.py --token YOUR_TOKEN --channel #alerts --alerts 1,3,5

# Post a range of alerts
python post_alerts_to_slack.py --token YOUR_TOKEN --channel #alerts --alerts 1-3

# Interactive mode - select which alerts to post
python post_alerts_to_slack.py --token YOUR_TOKEN --channel #alerts --interactive

# Using environment variables
export SLACK_TOKEN=xoxb-your-token
export SLACK_CHANNEL=#alerts
python post_alerts_to_slack.py --alerts 1,9
```

**Get Slack OAuth Token:**
1. Go to https://api.slack.com/apps
2. Create App → OAuth & Permissions
3. Add scopes: `chat:write`, `chat:write.public`
4. Install to workspace → Copy Bot User OAuth Token

### Expected AI Response

The AI will provide:
- **Root Cause Analysis**: Identifies the primary issue
- **Immediate Actions**: Actionable next steps
- **Investigation Checklist**: What to check
- **Long-term Prevention**: Recommendations to prevent recurrence
- **Code References**: Specific files and line numbers (if code context enabled)
- **Log Analysis**: Related error patterns from Kibana

## Configuration

### Workflow Channels

Edit in n8n workflow:
- **Input Channel**: Where alerts are posted (default: `#mcp-testing`)
- **Output Channel**: Where analysis is sent (default: `#n8n-output`)

### AI Temperature

Adjust in OpenAI node:
- `0.1-0.3`: More deterministic, consistent responses
- `0.4-0.7`: More creative, varied responses

### Severity Routing

Edit "Route by Severity" node to change which alerts get detailed analysis:
- **CRITICAL**: Full root cause analysis
- **HIGH/MEDIUM**: Quick analysis

## Project Structure

```
hackathon-2025/
├── dockers/                    # MCP server setup
│   ├── multi-mcp-docker-compose.yml
│   ├── mcp-bridge/            # HTTP bridge for MCP servers
│   ├── kibana-bridge/         # Kibana-specific bridge
│   ├── MULTI_MCP_SETUP.md
│   └── QUICK_START.md
├── n8n-workflow/              # n8n workflows
│   ├── production-alert-analyzer.json
│   ├── WORKFLOW_GUIDE.md
│   └── CODE_CONTEXT_GUIDE.md
├── sample-app/                # Spring Boot test application
│   └── src/main/java/...
├── sample-logs/               # Sample Kibana logs
│   ├── kibana-sample-logs.json
│   ├── convert-to-bulk.js
│   └── README.md
├── sample-alerts/             # Sample Slack alerts
│   ├── sample-slack-alerts.md
│   └── test-workflow.sh
└── TESTING_GUIDE.md          # Complete testing guide
```

## Documentation

- **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - Complete testing guide with scenarios
- **[n8n-workflow/WORKFLOW_GUIDE.md](n8n-workflow/WORKFLOW_GUIDE.md)** - n8n workflow details
- **[n8n-workflow/CODE_CONTEXT_GUIDE.md](n8n-workflow/CODE_CONTEXT_GUIDE.md)** - Adding code context
- **[dockers/MULTI_MCP_SETUP.md](dockers/MULTI_MCP_SETUP.md)** - Multi-MCP server setup
- **[sample-logs/README.md](sample-logs/README.md)** - Log import and testing
- **[sample-logs/KIBANA_IMPORT_GUIDE.md](sample-logs/KIBANA_IMPORT_GUIDE.md)** - Kibana import details

## Troubleshooting

### MCP Servers Not Starting

```bash
# Check logs
docker compose -f multi-mcp-docker-compose.yml logs

# Verify environment variables
cat .env

# Restart services
docker compose -f multi-mcp-docker-compose.yml restart
```

### n8n Workflow Not Triggering

1. Verify workflow is **Active** (toggle in top-right)
2. Check Slack credentials are valid
3. Verify channel IDs match your workspace
4. Test with simple message: "test CRITICAL alert"

### AI Response Too Generic

1. Add more context to alerts (service, metrics, stack traces)
2. Enable code context in workflow
3. Lower AI temperature (0.1-0.3)
4. Enhance system prompt with examples

### MCP Connection Issues

```bash
# Test bridges
curl http://localhost:3000/health
curl http://localhost:3001/health

# If n8n in Docker, use:
# http://host.docker.internal:3000/message
# http://host.docker.internal:3001/message
```

## Performance

- **Average Response Time**: 5-10 seconds
- **Token Usage**: 500-1500 tokens per alert
- **Cost**: ~$0.001-0.003 per alert (GPT-4o-mini)
- **Throughput**: 100+ alerts/hour

## Security Notes

⚠️ **Important**:
- Never commit `.env` files to version control
- Use read-only repository mounts when possible
- Restrict network access to MCP bridge ports
- Use API keys with minimal required permissions
- Consider adding authentication to HTTP bridges in production

## Next Steps

1. ✅ Test with all sample alerts
2. ✅ Customize prompts for your services
3. ✅ Add incident ticket creation (Jira/ServiceNow)
4. ✅ Integrate with monitoring systems (Datadog/Prometheus)
5. ✅ Build runbook database for AI reference
6. ✅ Add historical incident matching
7. ✅ Create metrics dashboard
8. ✅ Set up on-call escalation

## Contributing

This is a hackathon project. Feel free to:
- Add more MCP servers
- Enhance AI prompts
- Add new alert types
- Improve error handling
- Add more test scenarios

## License

MIT License - See LICENSE file for details

## Support

For issues or questions:
1. Check relevant documentation in subdirectories
2. Review Docker logs: `docker compose logs`
3. Test MCP bridges: `curl http://localhost:3000/health`
4. Verify n8n execution logs in UI
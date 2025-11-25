# Sample Logs for n8n Workflow Testing

## Overview

This directory contains realistic production logs that match the sample application code and alert scenarios. Use these logs to validate your n8n workflow that integrates GitHub MCP and Kibana MCP servers.

## Files

### 📄 `kibana-sample-logs.json`
**15 realistic log entries** matching production scenarios from `sample-alerts/sample-slack-alerts.md`

**Log Types:**
- ❌ **Errors**: Database timeouts, payment gateway failures, inventory service issues
- ⚠️ **Warnings**: High memory usage, slow queries, rate limits, disk space
- ℹ️ **Info**: Successful operations for comparison

**Key Features:**
- Timestamps match alert scenarios
- Stack traces reference actual code files (`OrderService.java:121`, `PaymentService.java:99`)
- Includes system metrics (CPU, memory, connections)
- Contains correlation IDs for tracing
- Structured JSON format ready for Elasticsearch

### 📄 `KIBANA_IMPORT_GUIDE.md`
**Complete guide** for importing logs into Kibana/Elasticsearch

**Includes:**
- 3 import methods (Dev Tools, Bulk API, Filebeat)
- Index mapping configuration
- Test queries for validation
- MCP tool usage examples
- Troubleshooting guide

### 📄 `convert-to-bulk.js`
**Node.js script** to convert JSON logs to Elasticsearch bulk format (NDJSON)

**Usage:**
```bash
node convert-to-bulk.js
# Creates: kibana-bulk-import.ndjson
```

## Quick Start

### 1. Generate Bulk Import File

```bash
cd sample-logs
node convert-to-bulk.js
```

### 2. Import to Elasticsearch

Replace `YOUR_KIBANA_URL` and `YOUR_API_KEY` with your actual values:

```bash
curl -X POST "https://YOUR_KIBANA_URL:9200/_bulk" \
  -H "Content-Type: application/x-ndjson" \
  -H "Authorization: ApiKey YOUR_API_KEY" \
  --data-binary @kibana-bulk-import.ndjson
```

### 3. Create Index Pattern in Kibana

1. Navigate to **Stack Management** → **Index Patterns**
2. Click **Create index pattern**
3. Enter: `logs-order-service-*`
4. Select time field: `@timestamp`
5. Click **Create**

### 4. Verify Import

```bash
curl -X GET "https://YOUR_KIBANA_URL:9200/logs-order-service-2025.11.21/_count" \
  -H "Authorization: ApiKey YOUR_API_KEY"
```

Expected: `{"count":15,...}`

## Log-Alert-Code Mapping

### Scenario 1: Database Timeout

**Alert**: `sample-alerts/sample-slack-alerts.md` - Alert 1  
**Logs**: Entries at `2025-11-21T14:23:45.123Z`, `14:23:46.234Z`, `14:23:48.456Z`  
**Code**: `sample-app/.../OrderService.java:121` (simulateProductionFailures)  
**Exception**: `DatabaseTimeoutException`

**Test Query:**
```json
{
  "query": {
    "match": { "exception.type": "DatabaseTimeoutException" }
  }
}
```

### Scenario 2: Payment Gateway Timeout

**Alert**: `sample-alerts/sample-slack-alerts.md` - Alert 2  
**Logs**: Entry at `2025-11-21T14:45:12.567Z`  
**Code**: `sample-app/.../PaymentService.java:99` (simulatePaymentGatewayFailures)  
**Exception**: `PaymentGatewayException`

**Test Query:**
```json
{
  "query": {
    "bool": {
      "must": [
        { "match": { "exception.type": "PaymentGatewayException" } },
        { "match": { "message": "Stripe" } }
      ]
    }
  }
}
```

### Scenario 3: Inventory Service Unavailable

**Alert**: `sample-alerts/sample-slack-alerts.md` - Alert 3  
**Logs**: Entries at `2025-11-21T15:02:33.890Z`, `15:02:35.901Z`  
**Code**: `sample-app/.../OrderService.java:137`, `InventoryService.java:45`  
**Exception**: `InventoryException`

**Test Query:**
```json
{
  "query": {
    "bool": {
      "must": [
        { "match": { "exception.type": "InventoryException" } },
        { "match": { "external_service.name": "inventory-service" } }
      ]
    }
  }
}
```

## Testing n8n Workflow

### Step 1: Ensure MCP Servers Running

```bash
cd dockers
docker compose -f multi-mcp-docker-compose.yml ps

# Should show:
# - multi-mcp-github-mcp-1 (Up)
# - multi-mcp-github-bridge-1 (Up, 0.0.0.0:3000->3000/tcp)
# - multi-mcp-kibana-mcp-1 (Up)
# - multi-mcp-kibana-bridge-1 (Up, 0.0.0.0:3001->3000/tcp)
```

### Step 2: Verify MCP Bridges

```bash
# Test GitHub bridge
curl http://localhost:3000/health

# Test Kibana bridge
curl http://localhost:3001/health

# Both should return: {"status":"ok","mcpConnected":true,...}
```

### Step 3: Test Kibana Query

```bash
curl -X POST http://localhost:3001/message \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "execute_kb_api",
      "arguments": {
        "method": "POST",
        "path": "/api/console/proxy?path=logs-order-service-*/_search&method=POST",
        "body": {
          "query": {
            "match": { "level": "ERROR" }
          },
          "size": 5
        }
      }
    },
    "id": 1
  }'
```

### Step 4: Send Test Alert to Slack

Copy any alert from `sample-alerts/sample-slack-alerts.md` and paste into your Slack `mcp-testing` channel.

**Example:**
```
🔴 *[CRITICAL] Database Query Timeout*

*Service:* `order-service`
*Time:* 2025-11-21 14:23:45 UTC

*Details:*
• *Error:* Database query exceeded 30s timeout
• *Stack Trace:* DatabaseTimeoutException at OrderService.java:89
```

### Step 5: Verify AI Response

The AI should respond in the `n8n-output` channel with:

1. **Log Analysis**:
   - Found X error logs at timestamp
   - Exception type: DatabaseTimeoutException
   - Connection pool exhausted (10/10)

2. **Code Analysis**:
   - Located in: `OrderService.java:121`
   - Method: `simulateProductionFailures()`
   - Root cause: Connection pool configuration

3. **Recommendations**:
   - Increase pool size
   - Add connection leak detection
   - Review recent deployments

## Sample Queries for MCP Testing

### Query 1: Find All Errors

```json
{
  "method": "POST",
  "path": "/api/console/proxy?path=logs-order-service-*/_search&method=POST",
  "body": {
    "query": {
      "match": { "level": "ERROR" }
    },
    "size": 10,
    "sort": [{ "@timestamp": "desc" }]
  }
}
```

### Query 2: Find Errors by Service

```json
{
  "method": "POST",
  "path": "/api/console/proxy?path=logs-order-service-*/_search&method=POST",
  "body": {
    "query": {
      "bool": {
        "must": [
          { "match": { "level": "ERROR" } },
          { "match": { "service.name": "order-service" } }
        ]
      }
    },
    "size": 10
  }
}
```

### Query 3: Find Errors in Time Range

```json
{
  "method": "POST",
  "path": "/api/console/proxy?path=logs-order-service-*/_search&method=POST",
  "body": {
    "query": {
      "bool": {
        "must": [
          { "match": { "level": "ERROR" } },
          {
            "range": {
              "@timestamp": {
                "gte": "2025-11-21T14:00:00Z",
                "lte": "2025-11-21T15:00:00Z"
              }
            }
          }
        ]
      }
    }
  }
}
```

### Query 4: Find Specific Exception Type

```json
{
  "method": "POST",
  "path": "/api/console/proxy?path=logs-order-service-*/_search&method=POST",
  "body": {
    "query": {
      "match": {
        "exception.type": "PaymentGatewayException"
      }
    }
  }
}
```

## Validation Checklist

- [ ] Logs imported to Elasticsearch (15 documents)
- [ ] Index pattern created (`logs-order-service-*`)
- [ ] Test queries work in Kibana Dev Tools
- [ ] MCP bridges are running and healthy
- [ ] Kibana MCP tool returns log data
- [ ] GitHub MCP tool returns code data
- [ ] n8n workflow is active
- [ ] Test alert triggers workflow
- [ ] AI response includes log analysis
- [ ] AI response includes code analysis
- [ ] AI response includes recommendations
- [ ] Response appears in Slack output channel

## Troubleshooting

### Logs Not Appearing

**Check:**
1. Index exists: `GET /logs-order-service-*/_count`
2. Time range in Kibana (set to last 30 days)
3. Index pattern refresh

### MCP Tool Not Working

**Check:**
1. Bridge health: `curl http://localhost:3001/health`
2. Kibana credentials in `.env`
3. Test query in Kibana Dev Tools first
4. Check bridge logs: `docker compose -f multi-mcp-docker-compose.yml logs kibana-bridge`

### AI Not Finding Logs

**Check:**
1. System prompt includes Kibana instructions
2. MCP client connected in n8n
3. Test execute_kb_api manually
4. Verify index name in queries

## Summary

✅ **15 realistic log entries** matching production scenarios  
✅ **Complete import guide** with multiple methods  
✅ **Conversion script** for bulk import  
✅ **Test queries** for validation  
✅ **Log-Alert-Code mapping** for end-to-end testing  
✅ **Troubleshooting guide** for common issues  

**Your n8n workflow can now analyze production alerts using both Kibana logs and GitHub code!** 🎉

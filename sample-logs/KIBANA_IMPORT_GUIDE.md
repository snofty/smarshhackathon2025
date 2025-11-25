# Kibana Sample Logs Import Guide

## Overview

This guide explains how to import the sample logs into your Kibana/Elasticsearch instance and test the n8n workflow with realistic production scenarios.

## Sample Logs Structure

The `kibana-sample-logs.json` file contains 15 log entries that match the alerts in `sample-alerts/sample-slack-alerts.md` and the code in `sample-app/`.

### Log Entry Fields

Each log entry includes:
- **@timestamp**: ISO 8601 timestamp
- **level**: ERROR, WARN, INFO, CRITICAL
- **service**: Service metadata (name, version, environment)
- **message**: Human-readable error message
- **exception**: Stack traces matching actual Java code
- **http**: Request details (method, path, status, response time)
- **host**: Server information
- **Additional context**: Database, memory, disk, external services, etc.

## Method 1: Import via Kibana Dev Tools (Recommended)

### Step 1: Access Kibana Dev Tools

1. Open your Kibana instance
2. Navigate to **Dev Tools** (hamburger menu → Management → Dev Tools)

### Step 2: Create Index

```json
PUT /logs-order-service-2025.11.21
{
  "mappings": {
    "properties": {
      "@timestamp": { "type": "date" },
      "level": { "type": "keyword" },
      "service": {
        "properties": {
          "name": { "type": "keyword" },
          "version": { "type": "keyword" },
          "environment": { "type": "keyword" }
        }
      },
      "message": { "type": "text" },
      "exception": {
        "properties": {
          "type": { "type": "keyword" },
          "message": { "type": "text" },
          "stacktrace": { "type": "text" }
        }
      },
      "http": {
        "properties": {
          "method": { "type": "keyword" },
          "path": { "type": "keyword" },
          "status_code": { "type": "integer" },
          "response_time_ms": { "type": "long" }
        }
      },
      "host": {
        "properties": {
          "name": { "type": "keyword" },
          "ip": { "type": "ip" }
        }
      }
    }
  }
}
```

### Step 3: Bulk Import Logs

```bash
# From the sample-logs directory
curl -X POST "https://your-kibana-url:9200/_bulk" \
  -H "Content-Type: application/x-ndjson" \
  -H "Authorization: ApiKey YOUR_API_KEY" \
  --data-binary @kibana-bulk-import.ndjson
```

Or use the bulk import script (see below).

### Step 4: Create Index Pattern

1. Go to **Stack Management** → **Index Patterns**
2. Click **Create index pattern**
3. Enter pattern: `logs-order-service-*`
4. Select time field: `@timestamp`
5. Click **Create index pattern**

## Method 2: Import via Elasticsearch Bulk API

### Step 1: Convert JSON to NDJSON Format

Run the conversion script:

```bash
cd sample-logs
node convert-to-bulk.js
```

This creates `kibana-bulk-import.ndjson` with the proper format:

```
{"index":{"_index":"logs-order-service-2025.11.21"}}
{...log entry 1...}
{"index":{"_index":"logs-order-service-2025.11.21"}}
{...log entry 2...}
```

### Step 2: Import Using curl

```bash
curl -X POST "https://your-kibana-url:9200/_bulk" \
  -H "Content-Type: application/x-ndjson" \
  -H "Authorization: ApiKey YOUR_API_KEY" \
  --data-binary @kibana-bulk-import.ndjson
```

### Step 3: Verify Import

```bash
curl -X GET "https://your-kibana-url:9200/logs-order-service-2025.11.21/_count" \
  -H "Authorization: ApiKey YOUR_API_KEY"
```

Expected response: `{"count":15,...}`

## Method 3: Import via Kibana UI (Filebeat)

### Step 1: Install Filebeat

```bash
# Download and install Filebeat
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.11.0-darwin-x86_64.tar.gz
tar xzvf filebeat-8.11.0-darwin-x86_64.tar.gz
cd filebeat-8.11.0-darwin-x86_64
```

### Step 2: Configure Filebeat

Edit `filebeat.yml`:

```yaml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /path/to/sample-logs/kibana-sample-logs.json
  json.keys_under_root: true
  json.add_error_key: true

output.elasticsearch:
  hosts: ["https://your-kibana-url:9200"]
  api_key: "YOUR_API_KEY"
  index: "logs-order-service-%{+yyyy.MM.dd}"

setup.ilm.enabled: false
```

### Step 3: Run Filebeat

```bash
./filebeat -e
```

## Testing the n8n Workflow

### Test Scenario 1: Database Timeout Alert

**1. Send Slack Alert:**

```
🔴 *[CRITICAL] Database Query Timeout*

*Service:* `order-service`
*Time:* 2025-11-21 14:23:45 UTC

*Details:*
• *Error:* Database query exceeded 30s timeout
• *Stack Trace:* DatabaseTimeoutException at OrderService.java:89
```

**2. Expected AI Response:**

The AI should:
1. Search Kibana logs for "DatabaseTimeoutException"
2. Find matching logs at 14:23:45 UTC
3. Search GitHub for "OrderService.java"
4. Read the file and find line 89 (or 121 where exception is thrown)
5. Provide analysis:
   - Root cause: Connection pool exhausted (10/10 connections)
   - Code location: `OrderService.java:121` in `simulateProductionFailures()`
   - Recommendation: Increase pool size, add connection leak detection

### Test Scenario 2: Payment Gateway Timeout

**1. Send Slack Alert:**

```
🟠 *[HIGH] Payment Gateway Timeout*

*Service:* `order-service`
*Time:* 2025-11-21 14:45:12 UTC

*Details:*
• *Error:* Payment gateway timeout - Stripe API not responding
• *Stack Trace:* PaymentGatewayException at PaymentService.java:67
```

**2. Expected AI Response:**

The AI should:
1. Search Kibana for "PaymentGatewayException" around 14:45:12
2. Find 30s timeout to Stripe API
3. Search GitHub for "PaymentService.java"
4. Identify line 67 (or 99 where exception is thrown)
5. Provide analysis:
   - Root cause: Stripe API timeout after 30s
   - Code location: `PaymentService.java:99` in `simulatePaymentGatewayFailures()`
   - Recommendation: Add retry logic, check Stripe status page

### Test Scenario 3: Inventory Service Unavailable

**1. Send Slack Alert:**

```
🟠 *[HIGH] Inventory Service Unavailable*

*Service:* `order-service`
*Time:* 2025-11-21 15:02:33 UTC

*Details:*
• *Error:* Inventory service returning HTTP 503
• *Stack Trace:* InventoryException at OrderService.java:102
```

**2. Expected AI Response:**

The AI should:
1. Search Kibana for "InventoryException" at 15:02:33
2. Find HTTP 503 from inventory-service
3. Search GitHub for "OrderService.java" and "InventoryService"
4. Identify circuit breaker pattern
5. Provide analysis:
   - Root cause: Inventory service DOWN, circuit breaker OPEN
   - Code location: `OrderService.java:137` and `InventoryService.java:45`
   - Recommendation: Check inventory service health, review fallback behavior

## Validation Queries

### Query 1: Find All Errors in Last Hour

```json
POST /logs-order-service-*/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "level": "ERROR" } },
        { "range": { "@timestamp": { "gte": "now-1h" } } }
      ]
    }
  },
  "size": 20,
  "sort": [{ "@timestamp": "desc" }]
}
```

### Query 2: Find Database Timeout Errors

```json
POST /logs-order-service-*/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "exception.type": "DatabaseTimeoutException" } }
      ]
    }
  }
}
```

### Query 3: Find Payment Gateway Errors

```json
POST /logs-order-service-*/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "exception.type": "PaymentGatewayException" } }
      ]
    }
  }
}
```

### Query 4: Find Slow Queries

```json
POST /logs-order-service-*/_search
{
  "query": {
    "bool": {
      "must": [
        { "range": { "http.response_time_ms": { "gte": 5000 } } }
      ]
    }
  },
  "sort": [{ "http.response_time_ms": "desc" }]
}
```

## MCP Tool Usage Examples

### Example 1: Search Logs via execute_kb_api

```json
{
  "method": "POST",
  "path": "/api/console/proxy?path=logs-order-service-*/_search&method=POST",
  "body": {
    "query": {
      "bool": {
        "must": [
          { "match": { "level": "ERROR" } },
          { "match": { "service.name": "order-service" } },
          { "range": { "@timestamp": { "gte": "2025-11-21T14:00:00Z", "lte": "2025-11-21T15:00:00Z" } } }
        ]
      }
    },
    "size": 10,
    "sort": [{ "@timestamp": "desc" }]
  }
}
```

### Example 2: Search for Specific Exception

```json
{
  "method": "POST",
  "path": "/api/console/proxy?path=logs-order-service-*/_search&method=POST",
  "body": {
    "query": {
      "match": {
        "exception.type": "DatabaseTimeoutException"
      }
    },
    "size": 5
  }
}
```

## Troubleshooting

### Issue: Logs Not Appearing in Kibana

**Solution:**
1. Check index exists: `GET /logs-order-service-*/_count`
2. Verify index pattern created
3. Check time range in Kibana (set to last 30 days)
4. Refresh index pattern

### Issue: MCP Tool Returns Empty Results

**Solution:**
1. Verify index name in query path
2. Check timestamp format and range
3. Test query directly in Kibana Dev Tools
4. Ensure Kibana credentials are correct in `.env`

### Issue: AI Not Finding Relevant Logs

**Solution:**
1. Check AI system prompt includes Kibana instructions
2. Verify MCP client is connected (check n8n logs)
3. Test execute_kb_api tool manually
4. Ensure log timestamps match alert timestamps

## Success Criteria

✅ **Logs imported successfully**: 15 documents in index  
✅ **Index pattern created**: `logs-order-service-*`  
✅ **Queries return results**: Test queries work in Dev Tools  
✅ **MCP tool works**: execute_kb_api returns log data  
✅ **AI correlates data**: AI finds logs AND code for alerts  
✅ **End-to-end flow**: Slack → AI → Kibana + GitHub → Slack response  

## Next Steps

1. Import the sample logs
2. Test queries in Kibana Dev Tools
3. Test MCP execute_kb_api tool manually
4. Send test alerts to Slack
5. Verify AI response includes both log and code analysis
6. Iterate on system prompt if needed

**Your n8n workflow should now be able to analyze production alerts using both Kibana logs and GitHub code!** 🎉

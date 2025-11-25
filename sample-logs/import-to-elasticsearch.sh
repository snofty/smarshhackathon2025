#!/bin/bash

# Import sample logs directly to Elasticsearch with proper structure
# This script deletes the old index and creates a new one with correct mappings

ES_URL="https://my-observability-project-e7d823.es.us-central1.gcp.elastic.cloud:443"
API_KEY="WmpmMXRab0J0VDg5VTRmOFlHWFc6N2h3TmRyVEF6cWc2SE9vVmYwZ0VZZw=="
INDEX_NAME="order-service-logs"

echo "================================"
echo "Elasticsearch Log Import Script"
echo "================================"
echo ""

# Step 1: Delete existing index (if it exists)
echo "1. Deleting existing index (if exists)..."
curl -s -X DELETE "$ES_URL/$INDEX_NAME" \
  -H "Authorization: ApiKey $API_KEY" | jq '.'
echo ""

# Step 2: Create index with proper mapping
echo "2. Creating index with proper mapping..."
curl -s -X PUT "$ES_URL/$INDEX_NAME" \
  -H "Content-Type: application/json" \
  -H "Authorization: ApiKey $API_KEY" \
  -d '{
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
        "database": {
          "properties": {
            "pool_size": { "type": "integer" },
            "active_connections": { "type": "integer" },
            "idle_connections": { "type": "integer" },
            "waiting_threads": { "type": "integer" }
          }
        },
        "host": {
          "properties": {
            "name": { "type": "keyword" },
            "ip": { "type": "ip" }
          }
        },
        "trace": {
          "properties": {
            "id": { "type": "keyword" },
            "span_id": { "type": "keyword" }
          }
        },
        "payment": {
          "properties": {
            "gateway": { "type": "keyword" },
            "transaction_id": { "type": "keyword" },
            "amount": { "type": "float" },
            "currency": { "type": "keyword" }
          }
        }
      }
    }
  }' | jq '.'
echo ""

# Step 3: Generate bulk import file
echo "3. Generating bulk import file..."
node convert-to-bulk.js
echo ""

# Step 4: Import data
echo "4. Importing logs to Elasticsearch..."
curl -s -X POST "$ES_URL/_bulk" \
  -H "Content-Type: application/x-ndjson" \
  -H "Authorization: ApiKey $API_KEY" \
  --data-binary @kibana-bulk-import.ndjson | jq '{took: .took, errors: .errors, items: (.items | length)}'
echo ""

# Step 5: Verify import
echo "5. Verifying import..."
sleep 2
curl -s -X GET "$ES_URL/$INDEX_NAME/_count" \
  -H "Authorization: ApiKey $API_KEY" | jq '.'
echo ""

# Step 6: Test search
echo "6. Testing search for ERROR logs..."
curl -s -X POST "$ES_URL/$INDEX_NAME/_search" \
  -H "Content-Type: application/json" \
  -H "Authorization: ApiKey $API_KEY" \
  -d '{
    "query": {
      "match": {
        "level": "ERROR"
      }
    },
    "size": 3
  }' | jq '{took: .took, total: .hits.total.value, hits: [.hits.hits[]._source | {timestamp: ."@timestamp", level: .level, message: .message}]}'

echo ""
echo "================================"
echo "Import completed!"
echo "================================"
echo ""
echo "Test queries:"
echo "1. All logs:"
echo "   curl -X POST \"$ES_URL/$INDEX_NAME/_search\" -H \"Authorization: ApiKey $API_KEY\" -H \"Content-Type: application/json\" -d '{\"query\":{\"match_all\":{}},\"size\":5}'"
echo ""
echo "2. ERROR logs only:"
echo "   curl -X POST \"$ES_URL/$INDEX_NAME/_search\" -H \"Authorization: ApiKey $API_KEY\" -H \"Content-Type: application/json\" -d '{\"query\":{\"match\":{\"level\":\"ERROR\"}},\"size\":5}'"
echo ""
echo "3. Via MCP Bridge:"
echo "   curl -X POST http://localhost:3001/message -H \"Content-Type: application/json\" -d '{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"execute_kb_api\",\"arguments\":{\"method\":\"POST\",\"path\":\"/$INDEX_NAME/_search\",\"body\":{\"query\":{\"match\":{\"level\":\"ERROR\"}},\"size\":5}}},\"id\":1}'"

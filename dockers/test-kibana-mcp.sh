#!/bin/bash

# Test script for Kibana MCP Bridge
# Tests various Kibana MCP tools and query formats

KIBANA_BRIDGE="http://localhost:3001/message"
INDEX="logs-order-service-2025.11.21"

echo "================================"
echo "Kibana MCP Bridge Test Script"
echo "================================"
echo ""

# Test 1: Check Kibana status
echo "1. Testing Kibana connectivity (get_status)..."
curl -s -X POST $KIBANA_BRIDGE \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "get_status",
      "arguments": {}
    },
    "id": 1
  }' | jq -r '.result.content[0].text' | jq '.status.overall.level' 2>/dev/null

if [ $? -eq 0 ]; then
  echo "✅ Kibana is reachable"
else
  echo "❌ Kibana connection failed"
fi
echo ""

# Test 2: List available spaces
echo "2. Listing available Kibana spaces..."
curl -s -X POST $KIBANA_BRIDGE \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "get_available_spaces",
      "arguments": {}
    },
    "id": 1
  }' | jq '.result.content[0].text' 2>/dev/null | head -10
echo ""

# Test 3: Search saved objects (to find data views/index patterns)
echo "3. Searching for data views..."
curl -s -X POST $KIBANA_BRIDGE \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "vl_search_saved_objects",
      "arguments": {
        "types": "index-pattern"
      }
    },
    "id": 1
  }' | jq '.'
echo ""

# Test 4: Try execute_kb_api with different path formats
echo "4. Testing execute_kb_api with various path formats..."

# Format 1: Direct API endpoint
echo "   a) Testing /api/status endpoint..."
curl -s -X POST $KIBANA_BRIDGE \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "execute_kb_api",
      "arguments": {
        "method": "GET",
        "path": "/api/status"
      }
    },
    "id": 1
  }' | jq '.result.isError'
echo ""

# Format 2: Console proxy with query params
echo "   b) Testing console proxy format..."
curl -s -X POST $KIBANA_BRIDGE \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"tools/call\",
    \"params\": {
      \"name\": \"execute_kb_api\",
      \"arguments\": {
        \"method\": \"POST\",
        \"path\": \"/api/console/proxy\",
        \"params\": {
          \"path\": \"$INDEX/_search\",
          \"method\": \"POST\"
        },
        \"body\": {
          \"query\": {
            \"match_all\": {}
          },
          \"size\": 1
        }
      }
    },
    \"id\": 1
  }" | jq '.'
echo ""

# Format 3: Try internal Elasticsearch endpoint
echo "   c) Testing internal/_search endpoint..."
curl -s -X POST $KIBANA_BRIDGE \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"tools/call\",
    \"params\": {
      \"name\": \"execute_kb_api\",
      \"arguments\": {
        \"method\": \"POST\",
        \"path\": \"/internal/_search\",
        \"body\": {
          \"params\": {
            \"index\": \"$INDEX\",
            \"body\": {
              \"query\": {
                \"match_all\": {}
              },
              \"size\": 1
            }
          }
        }
      }
    },
    \"id\": 1
  }" | jq '.'
echo ""

echo "================================"
echo "Test completed!"
echo "================================"

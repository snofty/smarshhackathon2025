# n8n Production Alert Analyzer Workflow

Enhanced workflow for analyzing production alerts with AI-powered root cause analysis.

## Overview

This workflow processes Slack alerts from production systems and provides intelligent analysis using OpenAI GPT-4o-mini.

## Workflow Architecture

```
Slack Alert Trigger
    ↓
Filter Valid Alerts (IF: contains CRITICAL/HIGH/MEDIUM)
    ↓
Parse Alert Details (Extract: severity, service, error type)
    ↓
    ├→ Send Acknowledgment (immediate feedback)
    └→ Route by Severity (SWITCH)
        ↓
        ├─ CRITICAL → AI Critical Analysis (detailed)
        └─ OTHER → AI Standard Analysis (concise)
            ↓
        Format Response (add structure and emoji)
            ↓
            ├→ Send Analysis to Slack (threaded reply)
            └→ Log Metrics (for tracking)
```

## Nodes Explained

### 1. Slack Alert Trigger
- **Type**: Slack Trigger
- **Purpose**: Listens for messages in `#mcp-testing` channel
- **Triggers on**: New messages
- **Output**: Raw Slack message data

### 2. Filter Valid Alerts
- **Type**: IF Node
- **Purpose**: Only process messages that look like alerts
- **Condition**: Message contains "CRITICAL", "HIGH", or "MEDIUM"
- **Why**: Prevents processing of non-alert messages

### 3. Parse Alert Details
- **Type**: Code Node (JavaScript)
- **Purpose**: Extract structured data from alert text
- **Extracts**:
  - Severity level (CRITICAL/HIGH/MEDIUM/LOW)
  - Service name (e.g., `order-service`)
  - Environment (e.g., `production`)
  - Error type (Database/Payment/Inventory/etc.)
  - Error rate percentage
  - Timestamp
  - Escalation flag
- **Output**: Structured JSON object

### 4. Send Acknowledgment
- **Type**: Slack Send
- **Purpose**: Immediate feedback that alert was received
- **Sends**: Quick status message in thread
- **Why**: Users know the system is working

### 5. Route by Severity
- **Type**: IF Node
- **Purpose**: Different analysis depth based on severity
- **Routes**:
  - **TRUE (CRITICAL)**: Detailed analysis with full RCA
  - **FALSE (HIGH/MEDIUM)**: Standard concise analysis

### 6. AI Critical Analysis
- **Type**: AI Agent (LangChain)
- **Model**: GPT-4o-mini (temperature: 0.3)
- **Purpose**: Deep root cause analysis for critical alerts
- **Provides**:
  1. Root Cause Analysis
  2. Immediate Mitigation Steps
  3. Investigation Checklist
  4. Long-term Prevention
  5. Related Context
- **System Prompt**: Expert SRE persona

### 7. AI Standard Analysis
- **Type**: AI Agent (LangChain)
- **Model**: GPT-4o-mini (temperature: 0.3)
- **Purpose**: Quick analysis for non-critical alerts
- **Provides**:
  1. Quick Assessment
  2. Recommended Actions
  3. Monitoring Guidelines
- **System Prompt**: SRE providing quick analysis

### 8. OpenAI GPT-4o-mini
- **Type**: Language Model
- **Model**: `gpt-4o-mini`
- **Settings**:
  - Temperature: 0.3 (more deterministic)
  - Max Tokens: 2000
- **Connected to**: Both AI analysis nodes

### 9. Format Response
- **Type**: Code Node (JavaScript)
- **Purpose**: Format AI output for Slack
- **Adds**:
  - Severity emoji (🔴🟠🟡🟢)
  - Service and error type header
  - Timestamp footer
  - Proper markdown formatting

### 10. Send Analysis to Slack
- **Type**: Slack Send
- **Purpose**: Send formatted analysis
- **Sends to**: `#n8n-output` channel
- **Format**: Threaded reply to original alert
- **Why**: Keeps conversation organized

### 11. Log Metrics
- **Type**: Code Node (JavaScript)
- **Purpose**: Log alert processing for metrics
- **Logs**:
  - Severity
  - Service
  - Error type
  - Timestamp
  - Escalation flag
- **Why**: Track alert patterns and response times

## Key Features

### ✅ Improvements Over Original Workflow

1. **Alert Parsing**: Extracts structured data from free-text alerts
2. **Severity Routing**: Different analysis depth based on criticality
3. **Immediate Acknowledgment**: Users get instant feedback
4. **Threaded Replies**: Responses stay organized in threads
5. **Better Text Extraction**: Handles various Slack message formats
6. **Correct Model**: Uses `gpt-4o-mini` instead of non-existent model
7. **Specialized Prompts**: Different prompts for critical vs standard alerts
8. **Response Formatting**: Clean, structured Slack output
9. **Metrics Logging**: Track alert processing
10. **Error Type Detection**: Identifies database, payment, inventory issues

### 🎯 Specialized for Production Alerts

- Recognizes common error patterns (timeout, connection pool, etc.)
- Extracts service names and environments
- Identifies error rates and thresholds
- Provides actionable remediation steps
- Links to relevant context (deployments, metrics)

## Configuration

### Required Credentials

1. **Slack API**
   - Name: `Slack account`
   - ID: `OOp6bAT8O0MLQYuB`
   - Scopes needed:
     - `channels:read`
     - `chat:write`
     - `channels:history`

2. **OpenAI API**
   - Name: `OpenAi account`
   - ID: `mg76fdBDeBhxX5hl`
   - Model: `gpt-4o-mini`

### Channel Configuration

- **Input Channel**: `#mcp-testing` (ID: `C09U815J5BQ`)
- **Output Channel**: `#n8n-output` (ID: `C09UKE4AHFW`)

To change channels:
1. Edit "Slack Alert Trigger" node
2. Select different channel from dropdown
3. Update "Send Analysis to Slack" node similarly

## Usage

### 1. Import Workflow

```bash
# In n8n UI:
# 1. Go to Workflows
# 2. Click "Import from File"
# 3. Select: production-alert-analyzer.json
# 4. Click "Import"
```

### 2. Configure Credentials

1. Click on "Slack Alert Trigger" node
2. Select or create Slack credentials
3. Click on "OpenAI GPT-4o-mini" node
4. Select or create OpenAI credentials

### 3. Activate Workflow

1. Click "Active" toggle in top-right
2. Workflow is now listening for alerts

### 4. Test with Sample Alert

Copy this alert to `#mcp-testing`:

```
🔴 *[CRITICAL] Database Query Timeout*

*Service:* `order-service`
*Environment:* `production`
*Time:* 2025-11-21 14:23:45 UTC

*Details:*
• *Error:* Database query exceeded 30s timeout
• *Connection Pool:* Exhausted (10/10 connections in use)
• *Impact:* Order creation API failing - 45% error rate
• *Error Rate:* 45% of requests in last 5 minutes
```

Expected flow:
1. Alert appears in `#mcp-testing`
2. Acknowledgment appears in thread (~1 second)
3. Analysis appears in `#n8n-output` (~5-10 seconds)

## Customization

### Adjust AI Temperature

For more creative responses:
```json
"options": {
  "temperature": 0.7  // Higher = more creative
}
```

For more deterministic responses:
```json
"options": {
  "temperature": 0.1  // Lower = more consistent
}
```

### Add More Error Types

Edit "Parse Alert Details" node:

```javascript
// Add new error type detection
else if (text.includes('Cache') || text.includes('cache')) {
  errorType = 'Cache Error';
}
```

### Change Severity Thresholds

Edit "Route by Severity" node to route HIGH alerts to critical analysis:

```json
"conditions": {
  "string": [
    {
      "value1": "={{ $json.severity }}",
      "operation": "equals",
      "value2": "CRITICAL"
    },
    {
      "value1": "={{ $json.severity }}",
      "operation": "equals",
      "value2": "HIGH"
    }
  ]
}
```

### Add Incident Ticket Creation

Add new node after "Route by Severity" (CRITICAL path):

1. Add HTTP Request node
2. Configure Jira/ServiceNow API
3. Create ticket with alert details
4. Link ticket ID in Slack response

### Add Metrics Dashboard

Add new node after "Log Metrics":

1. Add HTTP Request node
2. Send metrics to Datadog/Prometheus
3. Track:
   - Alert volume by severity
   - Response times
   - Error types distribution

## Monitoring

### Check Workflow Executions

1. Go to "Executions" tab
2. View recent runs
3. Check for errors
4. Review execution times

### View Logs

```javascript
// In "Log Metrics" node
console.log('Alert Processed:', {
  severity: alert.severity,
  service: alert.service,
  errorType: alert.errorType
});
```

Logs appear in n8n execution details.

## Troubleshooting

### Issue: Workflow not triggering

**Solutions:**
1. Check workflow is Active (toggle in top-right)
2. Verify Slack credentials are valid
3. Check channel ID is correct
4. Test Slack connection in credentials

### Issue: AI response is generic

**Solutions:**
1. Add more context to alert messages
2. Include error details, metrics, stack traces
3. Lower temperature for more focused responses
4. Enhance system prompt with more examples

### Issue: Responses too slow

**Solutions:**
1. Use `gpt-4o-mini` instead of `gpt-4o` (faster)
2. Reduce max tokens
3. Simplify prompt
4. Remove unnecessary nodes

### Issue: Wrong channel

**Solutions:**
1. Edit "Slack Alert Trigger" node
2. Click channel dropdown
3. Select correct channel
4. Save workflow

## Performance

- **Average Response Time**: 5-10 seconds
- **Token Usage**: ~500-1500 tokens per alert
- **Cost**: ~$0.001-0.003 per alert (GPT-4o-mini)
- **Throughput**: Can handle 100+ alerts/hour

## Best Practices

1. **Keep alerts structured**: Use consistent format
2. **Include context**: Service, environment, metrics
3. **Use severity levels**: CRITICAL/HIGH/MEDIUM/LOW
4. **Add timestamps**: For time-based analysis
5. **Include error rates**: Helps assess impact
6. **Link to dashboards**: Provide investigation links
7. **Test regularly**: Use sample alerts
8. **Monitor costs**: Track OpenAI API usage
9. **Review responses**: Improve prompts based on output
10. **Document patterns**: Build knowledge base

## Next Steps

1. ✅ Import and activate workflow
2. ✅ Test with sample alerts
3. ✅ Customize prompts for your services
4. ✅ Add incident ticket creation
5. ✅ Integrate with monitoring systems
6. ✅ Build runbook database
7. ✅ Add historical incident matching
8. ✅ Create metrics dashboard
9. ✅ Set up on-call escalation
10. ✅ Document common patterns

## Files

- `production-alert-analyzer.json` - Enhanced workflow
- `slack-2-ai-2-slack.json` - Original simple workflow
- `WORKFLOW_GUIDE.md` - This documentation

## Support

For issues or questions:
1. Check n8n execution logs
2. Review OpenAI API usage
3. Test with simple alerts first
4. Verify all credentials are valid

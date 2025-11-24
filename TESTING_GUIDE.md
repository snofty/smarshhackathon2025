# Testing Guide: n8n Slack Alert Analysis Workflow

Complete guide for testing your n8n workflow with the sample Spring Boot application.

## Overview

This setup includes:
1. **Spring Boot Order Service** - Generates realistic production failures
2. **Sample Alert Messages** - Pre-formatted Slack alerts for testing
3. **n8n Workflow** - Analyzes alerts and provides AI-powered insights

## Quick Start

### Step 1: Start the Spring Boot Application

```bash
cd sample-app

# Build and run
mvn clean install
mvn spring-boot:run
```

The service starts on `http://localhost:8080`

Verify it's running:
```bash
curl http://localhost:8080/health
```

### Step 2: Test the Application

Generate some traffic to trigger failures:

```bash
cd ../sample-alerts
chmod +x test-workflow.sh
./test-workflow.sh
```

This will:
- Create 20+ orders (triggering random failures)
- Process payments (triggering gateway timeouts)
- Test validation errors
- Generate high load

### Step 3: Test n8n Workflow with Sample Alerts

#### Option A: Manual Testing

1. Open your Slack workspace
2. Go to the `#mcp-testing` channel (or your configured channel)
3. Copy any alert from `sample-alerts/sample-slack-alerts.md`
4. Paste the alert message in Slack
5. n8n workflow should trigger automatically
6. Check `#n8n-output` channel for AI analysis

#### Option B: Automated Testing

Use curl to test the workflow directly (if you have webhook access):

```bash
# Example: Send alert to n8n webhook
curl -X POST "YOUR_N8N_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "🔴 *[CRITICAL] Database Query Timeout*\n\n*Service:* `order-service`..."
  }'
```

## Testing Scenarios

### Scenario 1: Database Timeout (Critical)

**Alert to Test:**
```
🔴 *[CRITICAL] Database Query Timeout*

*Service:* `order-service`
*Environment:* `production`
*Time:* 2025-11-21 14:23:45 UTC

*Details:*
• *Error:* Database query exceeded 30s timeout
• *Connection Pool:* Exhausted (10/10 connections in use)
• *Impact:* Order creation API failing - 45% error rate
```

**Expected AI Response:**
- Identifies database connection pool exhaustion
- Suggests immediate restart
- Recommends increasing pool size
- Mentions checking recent deployments
- Provides query optimization tips

### Scenario 2: Payment Gateway Timeout (High)

**Alert to Test:**
```
🟠 *[HIGH] Payment Gateway Timeout*

*Service:* `order-service`
*Environment:* `production`

*Details:*
• *Error:* Payment gateway timeout - Stripe API not responding
• *Timeout:* 30s exceeded
• *Affected Orders:* 23 orders stuck in PAYMENT_PENDING status
```

**Expected AI Response:**
- Identifies external service dependency issue
- Suggests checking Stripe status page
- Recommends implementing retry logic
- Mentions circuit breaker pattern
- Estimates customer impact

### Scenario 3: High Error Rate (Critical)

**Alert to Test:**
```
🔴 *[CRITICAL] High Error Rate Detected*

*Service:* `order-service`
*Error Rate:* 52% (260 errors / 500 requests)

*Primary Errors:*
  - DatabaseTimeoutException: 45%
  - PaymentGatewayException: 15%
```

**Expected AI Response:**
- Identifies multiple cascading failures
- Prioritizes database issue as primary cause
- Suggests immediate escalation
- Recommends creating P1 incident
- Provides war room coordination steps

## Validation Checklist

After each test, verify the AI response includes:

- [ ] **Severity Recognition**: Correctly identifies CRITICAL/HIGH/MEDIUM
- [ ] **Service Identification**: Extracts service name (`order-service`)
- [ ] **Environment**: Recognizes production environment
- [ ] **Root Cause**: Identifies the primary issue
- [ ] **Impact Assessment**: Understands customer/business impact
- [ ] **Immediate Actions**: Provides actionable next steps
- [ ] **Investigation Steps**: Suggests what to check
- [ ] **Long-term Fixes**: Recommends preventive measures
- [ ] **Related Context**: Links to deployments, metrics, etc.

## Monitoring the Application

### View Real-time Metrics

```bash
# Get current metrics
curl http://localhost:8080/api/metrics | jq

# Expected output:
{
  "service": "order-service",
  "totalRequests": 150,
  "failedRequests": 45,
  "errorRate": "30.00%",
  "avgResponseTimeMs": "1250.50",
  "memoryUsageMb": 512
}
```

### Check Application Logs

```bash
# View logs in real-time
tail -f logs/application.log

# Look for error patterns:
# - DatabaseTimeoutException
# - PaymentGatewayException
# - InventoryException
```

### Monitor Failure Rates

The application has built-in failure simulation:
- **Database Timeout**: 10% of requests
- **Database Connection Error**: 5% of requests
- **Inventory Failure**: 8% of requests
- **Payment Timeout**: 15% of payment requests
- **Payment Declined**: 10% of payment requests

## Troubleshooting

### Issue: Service won't start

**Solution:**
```bash
# Check if port 8080 is already in use
lsof -i :8080

# Kill existing process if needed
kill -9 <PID>

# Or run on different port
mvn spring-boot:run -Dspring-boot.run.arguments=--server.port=8081
```

### Issue: No failures occurring

**Solution:**
The failures are random. Generate more traffic:
```bash
# Run test script multiple times
for i in {1..5}; do
  ./test-workflow.sh
  sleep 2
done
```

### Issue: n8n workflow not triggering

**Solution:**
1. Check Slack channel ID in workflow matches your channel
2. Verify Slack credentials are configured
3. Check n8n workflow is activated
4. Test with simple message first: "test alert"

### Issue: AI response is generic

**Solution:**
1. Ensure alert message includes enough context
2. Add more details: service name, error type, metrics
3. Include stack traces and error messages
4. Provide recent deployment information

## Advanced Testing

### Custom Alert Generation

Create your own alert messages following this template:

```
🔴 *[SEVERITY] Alert Title*

*Service:* `service-name`
*Environment:* `production`
*Time:* YYYY-MM-DD HH:MM:SS UTC

*Details:*
• *Error:* Detailed error message
• *Impact:* What is affected
• *Metrics:* Relevant numbers
• *Stack Trace:* Error location

*Context:*
• Recent changes
• Related incidents
```

### Load Testing

Generate sustained load to trigger multiple failures:

```bash
# Install Apache Bench
brew install apache-bench  # macOS

# Generate 1000 requests with 50 concurrent
ab -n 1000 -c 50 -p order.json -T application/json \
   http://localhost:8080/api/orders
```

Where `order.json` contains:
```json
{
  "customerId": "CUST-001",
  "productId": "PROD-001",
  "quantity": 1,
  "totalAmount": 99.99
}
```

### Monitoring Integration

To send real alerts to Slack from the application:

1. Add Slack webhook to application
2. Configure alert thresholds
3. Implement alert formatter
4. Send alerts on exception

Example (add to `GlobalExceptionHandler.java`):

```java
private void sendSlackAlert(Exception ex) {
    String alert = formatAlert(ex);
    // Send to Slack webhook
    restTemplate.postForEntity(
        slackWebhookUrl,
        new SlackMessage(alert),
        String.class
    );
}
```

## Success Metrics

Your workflow is working correctly if:

1. **Response Time**: AI responds within 5-10 seconds
2. **Accuracy**: Root cause identified correctly >80% of time
3. **Actionability**: Provides specific, actionable steps
4. **Context**: Includes relevant deployment/metric information
5. **Formatting**: Response is well-formatted in Slack

## Next Steps

1. ✅ Test with all 10 sample alerts
2. ✅ Verify AI responses are accurate
3. ✅ Add more context to workflow (deployment history, runbooks)
4. ✅ Implement action buttons in Slack responses
5. ✅ Add incident ticket creation
6. ✅ Integrate with monitoring systems (Datadog, Prometheus)
7. ✅ Create runbook database for AI to reference
8. ✅ Add historical incident matching

## Resources

- **Application Code**: `sample-app/`
- **Sample Alerts**: `sample-alerts/sample-slack-alerts.md`
- **Test Script**: `sample-alerts/test-workflow.sh`
- **n8n Workflow**: `n8n-workflow/slack-2-ai-2-slack.json`
- **API Documentation**: `sample-app/README.md`

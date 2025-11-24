# Sample Slack Alert Messages for Testing n8n Workflow

These are realistic production alert messages you can use to test your n8n Slack-to-AI-to-Slack workflow.

---

## Alert 1: Database Timeout - CRITICAL

```
🔴 *[CRITICAL] Database Query Timeout*

*Service:* `order-service`
*Environment:* `production`
*Time:* 2025-11-21 14:23:45 UTC

*Details:*
• *Error:* Database query exceeded 30s timeout
• *Query:* SELECT * FROM orders WHERE status='PENDING' AND created_at > NOW() - INTERVAL 1 HOUR
• *Connection Pool:* Exhausted (10/10 connections in use)
• *Impact:* Order creation API failing - 45% error rate
• *Affected Endpoints:* POST /api/orders
• *Error Rate:* 45% of requests in last 5 minutes
• *Request Count:* 234 failed out of 520 total
• *Stack Trace:* DatabaseTimeoutException at OrderService.java:89
  → HikariPool.getConnection() timeout after 30000ms

*Recent Deployments:*
• order-service v1.2.3 deployed 2 hours ago
• Database migration #456 applied 3 hours ago

*Metrics:*
• CPU: 85%
• Memory: 92% (7.2GB / 8GB)
• Active Connections: 10/10
• Queue Depth: 47 pending queries
```

---

## Alert 2: Payment Gateway Timeout - HIGH

```
🟠 *[HIGH] Payment Gateway Timeout*

*Service:* `order-service`
*Environment:* `production`
*Time:* 2025-11-21 14:45:12 UTC

*Details:*
• *Error:* Payment gateway timeout - Stripe API not responding
• *Gateway:* Stripe Payment API (api.stripe.com)
• *Timeout:* 30s exceeded
• *Impact:* Payment processing failing
• *Affected Orders:* 23 orders stuck in PAYMENT_PENDING status
• *Error Rate:* 15% of payment requests
• *Response Code:* 504 Gateway Timeout
• *Stack Trace:* PaymentGatewayException at PaymentService.java:67
  → RestTemplate.postForEntity() timeout

*External Service Status:*
• Stripe Status Page: All systems operational
• Network Latency: 2500ms (normal: 150ms)
• Last Successful Payment: 5 minutes ago

*Customer Impact:*
• 23 customers unable to complete checkout
• Estimated revenue impact: $4,567
```

---

## Alert 3: Inventory Service Unavailable - HIGH

```
🟠 *[HIGH] Inventory Service Unavailable*

*Service:* `order-service`
*Environment:* `production`
*Time:* 2025-11-21 15:02:33 UTC

*Details:*
• *Error:* Inventory service returning HTTP 503
• *Service URL:* http://inventory-service.prod.internal:8080
• *Impact:* Cannot validate product availability
• *Affected Endpoints:* POST /api/orders
• *Error Rate:* 8% of order creation requests
• *Failed Requests:* 42 in last 10 minutes
• *Stack Trace:* InventoryException at OrderService.java:102
  → FeignClient call to inventory-service failed

*Service Health:*
• Inventory Service: DOWN
• Last Successful Call: 12 minutes ago
• Circuit Breaker: OPEN (after 5 consecutive failures)

*Fallback Behavior:*
• Using cached inventory data (15 minutes old)
• Risk of overselling out-of-stock items
```

---

## Alert 4: High Memory Usage - MEDIUM

```
🟡 *[MEDIUM] High Memory Usage Detected*

*Service:* `order-service`
*Environment:* `production`
*Time:* 2025-11-21 15:15:20 UTC

*Details:*
• *Memory Usage:* 7.8GB / 8GB (97.5%)
• *Trend:* Increasing 50MB every 5 minutes
• *Heap Usage:* 95% (7.6GB / 8GB)
• *GC Activity:* Full GC every 30 seconds
• *Impact:* Degraded performance, increased latency
• *Avg Response Time:* 3200ms (normal: 250ms)

*Analysis:*
• Possible memory leak detected
• Heap dump captured: /var/logs/heap-dump-20251121-151520.hprof
• Top memory consumers:
  - OrderCache: 2.1GB
  - HTTP Connection Pool: 1.8GB
  - Session Store: 1.5GB

*Recommendation:*
• Restart service to free memory
• Investigate OrderCache growth
• Review recent code changes for memory leaks
```

---

## Alert 5: High Error Rate - CRITICAL

```
🔴 *[CRITICAL] High Error Rate Detected*

*Service:* `order-service`
*Environment:* `production`
*Time:* 2025-11-21 15:30:45 UTC

*Details:*
• *Error Rate:* 52% (260 errors / 500 requests)
• *Time Window:* Last 10 minutes
• *Threshold:* 10% (exceeded by 5.2x)
• *Primary Errors:*
  - DatabaseTimeoutException: 45%
  - PaymentGatewayException: 15%
  - InventoryException: 8%
  - ValidationException: 5%

*Affected Endpoints:*
• POST /api/orders: 45% error rate
• POST /api/payment/process: 15% error rate
• GET /api/orders/{id}: 2% error rate

*System Metrics:*
• CPU: 92%
• Memory: 95%
• Disk I/O: 85%
• Network: Normal

*Customer Impact:*
• ~260 failed transactions in last 10 minutes
• Estimated revenue loss: $15,000+
• Customer complaints increasing

*Incident Status:*
• Severity: P1 (Critical)
• On-call engineer: @john.doe paged
• War room: #incident-20251121-001
```

---

## Alert 6: Database Connection Pool Exhausted - CRITICAL

```
🔴 *[CRITICAL] Database Connection Pool Exhausted*

*Service:* `order-service`
*Environment:* `production`
*Time:* 2025-11-21 16:00:12 UTC

*Details:*
• *Error:* Failed to acquire database connection from pool
• *Pool Status:* 10/10 connections in use
• *Wait Queue:* 67 threads waiting
• *Longest Wait:* 45 seconds
• *Impact:* All database operations failing
• *Error Message:* HikariPool-1 - Connection is not available, request timed out after 30000ms

*Connection Details:*
• Max Pool Size: 10
• Min Idle: 5
• Connection Timeout: 30s
• Idle Timeout: 10m
• Max Lifetime: 30m

*Active Connections:*
• 8 connections in ACTIVE state (>30s)
• 2 connections in IDLE state
• Possible connection leak detected

*Root Cause Analysis:*
• Long-running queries holding connections
• Possible missing connection.close() in error paths
• Recent deployment may have introduced connection leak

*Immediate Actions:*
• Restart application to reset connection pool
• Review recent code changes
• Enable connection leak detection
```

---

## Alert 7: Deployment Rollback Required - HIGH

```
🟠 *[HIGH] Deployment Rollback Required*

*Service:* `order-service`
*Environment:* `production`
*Time:* 2025-11-21 16:30:00 UTC

*Details:*
• *Deployment:* order-service v1.2.4
• *Deployed:* 15 minutes ago
• *Status:* FAILING
• *Error Rate:* Increased from 2% to 35% post-deployment
• *Impact:* Significant service degradation

*Deployment Info:*
• Version: v1.2.4
• Deployed By: jenkins-ci
• Commit: abc123def456
• Deployment Time: 16:15 UTC

*Comparison (Pre vs Post Deployment):*
• Error Rate: 2% → 35%
• Avg Response Time: 250ms → 2800ms
• Throughput: 100 req/s → 45 req/s
• Memory Usage: 60% → 92%

*Failed Health Checks:*
• /health endpoint: 200 OK (passing)
• /actuator/health: Degraded
• Database connectivity: OK
• External services: OK

*Recommendation:*
• Immediate rollback to v1.2.3
• Investigate changes in v1.2.4
• Review deployment logs
```

---

## Alert 8: API Rate Limit Exceeded - MEDIUM

```
🟡 *[MEDIUM] External API Rate Limit Exceeded*

*Service:* `order-service`
*Environment:* `production`
*Time:* 2025-11-21 17:00:45 UTC

*Details:*
• *External Service:* Stripe Payment API
• *Error:* Rate limit exceeded - 429 Too Many Requests
• *Current Rate:* 150 requests/minute
• *Allowed Rate:* 100 requests/minute
• *Impact:* Payment processing throttled
• *Retry After:* 60 seconds

*Request Statistics:*
• Total Requests (last hour): 8,500
• Rate Limit Errors: 450
• Success Rate: 94.7%

*Traffic Analysis:*
• Normal traffic: 80 req/min
• Current traffic: 150 req/min (87.5% increase)
• Possible cause: Marketing campaign launched 2 hours ago

*Mitigation:*
• Implement request queuing
• Add exponential backoff
• Contact Stripe to increase rate limit
• Consider caching payment method validation
```

---

## Alert 9: Disk Space Critical - HIGH

```
🟠 *[HIGH] Disk Space Critical*

*Service:* `order-service`
*Environment:* `production`
*Host:* `prod-order-service-01`
*Time:* 2025-11-21 17:30:22 UTC

*Details:*
• *Disk Usage:* 95% (190GB / 200GB)
• *Available Space:* 10GB remaining
• *Threshold:* 90% (exceeded)
• *Growth Rate:* 2GB per hour
• *Estimated Full:* 5 hours

*Disk Breakdown:*
• /var/logs: 85GB (application logs)
• /var/lib/mysql: 60GB (database)
• /tmp: 25GB (temporary files)
• /app: 20GB (application files)

*Log Files:*
• order-service.log: 45GB
• access.log: 30GB
• error.log: 10GB

*Immediate Actions:*
• Rotate and compress old logs
• Clean up temporary files
• Archive old database backups
• Increase disk size or add volume
```

---

## Alert 10: Slow Query Detected - MEDIUM

```
🟡 *[MEDIUM] Slow Query Detected*

*Service:* `order-service`
*Environment:* `production`
*Time:* 2025-11-21 18:00:15 UTC

*Details:*
• *Query Duration:* 15.3 seconds
• *Threshold:* 1 second (exceeded by 15x)
• *Frequency:* 45 occurrences in last hour
• *Impact:* Degraded performance for order history endpoint

*Query:*
```sql
SELECT o.*, c.name, p.title, p.price 
FROM orders o 
JOIN customers c ON o.customer_id = c.id 
JOIN products p ON o.product_id = p.id 
WHERE o.created_at >= '2025-01-01' 
ORDER BY o.created_at DESC
```

*Analysis:*
• Missing index on orders.created_at
• Full table scan on 2.5M rows
• No query optimization
• Cartesian product risk

*Recommendations:*
• Add index: CREATE INDEX idx_orders_created_at ON orders(created_at)
• Add query limit/pagination
• Consider materialized view for reporting
• Review query execution plan
```

---

## How to Use These Alerts

### For Testing Your n8n Workflow:

1. **Copy any alert message** from above
2. **Paste into your Slack channel** (mcp-testing or configured channel)
3. **n8n workflow should trigger** and analyze the alert
4. **AI should provide**:
   - Root cause analysis
   - Severity assessment
   - Remediation steps
   - Related incidents

### Expected AI Analysis Example:

For Alert 1 (Database Timeout), the AI should identify:
- **Root Cause**: Connection pool exhaustion + slow queries
- **Immediate Action**: Restart service to reset pool
- **Investigation**: Check recent deployment and database migration
- **Long-term Fix**: Increase pool size, optimize queries, add connection leak detection

### Testing Different Scenarios:

- **Critical Alerts** (1, 5, 6): Should trigger immediate escalation
- **High Alerts** (2, 3, 7, 9): Should create incident tickets
- **Medium Alerts** (4, 8, 10): Should log and monitor

### Validation Checklist:

- [ ] AI correctly identifies severity level
- [ ] AI extracts service name and environment
- [ ] AI identifies error type and root cause
- [ ] AI suggests appropriate remediation steps
- [ ] AI links to relevant context (deployments, metrics)
- [ ] Response is formatted properly for Slack
- [ ] Response includes actionable next steps

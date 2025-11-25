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

## Alert 11: Datadog Monitor - High CPU Usage - CRITICAL

```
🔴 *[Datadog Monitor Alert] High CPU Usage on order-service*

*Monitor:* `[P1] order-service CPU usage > 90%`
*Monitor ID:* `12345678`
*Status:* `ALERT` (triggered)
*Priority:* `P1`
*Environment:* `production`
*Time:* 2025-11-21 18:30:00 UTC

*Alert Details:*
• *Metric:* `system.cpu.user`
• *Current Value:* 94.5%
• *Threshold:* > 90% for 5 minutes
• *Duration:* Alert active for 12 minutes
• *Evaluation Window:* Last 5 minutes

*Triggered Scope:*
• *Host:* `prod-order-service-01.us-east-1.compute.internal`
• *Service:* `order-service`
• *Environment:* `production`
• *Region:* `us-east-1`
• *Instance Type:* `c5.2xlarge` (8 vCPUs)

*Metric Values (Last 15 min):*
```
18:15 UTC: 78.2%
18:20 UTC: 85.4%
18:25 UTC: 91.3%
18:30 UTC: 94.5% ← ALERT
```

*Related Metrics:*
• *Load Average:* 12.5 (normal: 4.0)
• *Memory Usage:* 87% (6.96GB / 8GB)
• *Disk I/O:* 450 IOPS (normal: 150 IOPS)
• *Network Traffic:* 250 Mbps (normal: 80 Mbps)

*Top Processes (by CPU):*
1. java (order-service): 85% CPU
2. mysqld: 6% CPU
3. node_exporter: 2% CPU

*Recent Events:*
• 18:15 UTC: Traffic spike detected (+150%)
• 18:10 UTC: Deployment completed (v1.2.5)
• 17:45 UTC: Database migration started

*APM Traces:*
• Slow traces detected: 45 traces > 2s
• Top slow endpoint: `POST /api/orders` (avg 3.2s)
• Error rate: 12% (up from 2%)

*Logs (Last 10 min):*
```
ERROR [order-service] OutOfMemoryError: GC overhead limit exceeded
WARN  [order-service] Thread pool exhausted: 200/200 threads active
ERROR [order-service] Database connection timeout after 30s
```

*Datadog Links:*
• Monitor: https://app.datadoghq.com/monitors/12345678
• Dashboard: https://app.datadoghq.com/dashboard/abc-123
• APM Service: https://app.datadoghq.com/apm/service/order-service
• Logs: https://app.datadoghq.com/logs?query=service:order-service

*Notification Settings:*
• *Notified:* @pagerduty-oncall, @slack-alerts, @ops-team
• *Escalation:* Auto-escalate to @engineering-lead in 15 minutes
• *Runbook:* https://wiki.company.com/runbooks/high-cpu-order-service

*Suggested Actions:*
1. Check for memory leaks causing excessive GC
2. Review recent deployment (v1.2.5) for performance issues
3. Scale horizontally: Add 2 more instances
4. Investigate slow database queries
5. Consider rolling back to v1.2.4 if issue persists

*Tags:*
`env:production` `service:order-service` `region:us-east-1` `team:platform` `severity:critical`
```

---

## Alert 12: Datadog Monitor - Short Format - HIGH

```
🟠 *[Datadog Alert] Memory Usage Spike*

*Monitor:* `order-service memory > 85%` (ID: 87654321)
*Status:* ALERT | *Priority:* P2
*Host:* prod-order-service-02 | *Env:* production

*Metric:* `system.mem.used` = 91.2% (threshold: 85%)
*Duration:* 8 minutes

*Quick Stats:*
• Memory: 91.2% (7.3GB / 8GB)
• Swap: 45% in use
• Top process: java (6.8GB)

*Links:*
• Monitor: https://app.datadoghq.com/monitors/87654321
• Dashboard: https://app.datadoghq.com/dashboard/mem-xyz

*Action:* Investigate memory leak or restart service if OOM imminent

Tags: `env:production` `service:order-service` `team:platform`
```

---

## Alert 14: Datadog Metric Alert - Order Success Rate Below Threshold - HIGH

```
🟠 *[Datadog Metric Alert] Order Success Rate Dropped Below 75%*

*Monitor:* `Order Success Rate < 75%` (ID: 98765432)
*Status:* ALERT | *Priority:* P2
*Environment:* `production` | *Service:* `order-service`
*Time:* 2025-11-21 20:45:00 UTC

*Metric Alert Details:*
• *Metric:* `order.success.rate`
• *Current Value:* 68.5%
• *Threshold:* < 75% for 10 minutes
• *Alert Duration:* 15 minutes
• *Evaluation:* `(sum:order.success.count / sum:order.total.count) * 100`

*Metric Breakdown (Last 15 min):*
```
20:30 UTC: 82.3% ✓
20:35 UTC: 76.1% ✓
20:40 UTC: 71.2% ← ALERT
20:45 UTC: 68.5% ← CURRENT
```

*Order Statistics:*
• Total Orders: 1,250
• Successful Orders: 856 (68.5%)
• Failed Orders: 394 (31.5%)
• Orders/min: 83 (normal: 75)

*Failure Breakdown by Error Type:*
• Payment Gateway Timeout: 45% (177 orders)
• Database Connection Error: 30% (118 orders)
• Inventory Service Unavailable: 15% (59 orders)
• Validation Errors: 10% (40 orders)

*Related Metrics:*
• `order.error.rate`: 31.5% (threshold: 10%)
• `order.response.time.p95`: 4.2s (normal: 0.8s)
• `order.payment.timeout.count`: 177 (spike detected)
• `database.connection.pool.exhausted`: 12 occurrences

*Correlated Events:*
• 20:30 UTC: Traffic spike +40% (Black Friday sale started)
• 20:35 UTC: Payment gateway latency increased to 3.5s
• 20:38 UTC: Database connection pool at 95% capacity

*Customer Impact:*
• Failed transactions: 394
• Estimated revenue loss: $28,450
• Customer support tickets: +85 in last 15 min

*Datadog Links:*
• Monitor: https://app.datadoghq.com/monitors/98765432
• Metrics Dashboard: https://app.datadoghq.com/dashboard/orders-metrics
• APM: https://app.datadoghq.com/apm/service/order-service
• Custom Metric: https://app.datadoghq.com/metric/explorer?metric=order.success.rate

*Recommended Actions:*
1. Scale order-service instances (current: 4 → target: 8)
2. Increase database connection pool size
3. Enable payment gateway circuit breaker
4. Review Black Friday capacity planning

*Tags:* `env:production` `service:order-service` `metric:order.success.rate` `team:platform`
```

### Custom Metrics Published to Datadog

**File: `src/main/java/com/company/order/metrics/OrderMetricsPublisher.java`**

```java
@Component
public class OrderMetricsPublisher {
    
    private final StatsDClient statsd;
    
    @Autowired
    public OrderMetricsPublisher(StatsDClient statsd) {
        this.statsd = statsd;
    }
    
    /**
     * Publishes order success/failure metrics to Datadog
     */
    public void recordOrderSuccess(Order order) {
        // Increment success counter
        statsd.incrementCounter("order.success.count", 
            "env:production", 
            "service:order-service",
            "payment_method:" + order.getPaymentMethod());
        
        // Increment total counter
        statsd.incrementCounter("order.total.count",
            "env:production",
            "service:order-service");
        
        // Record order amount
        statsd.recordGaugeValue("order.amount", 
            order.getTotalAmount().doubleValue(),
            "env:production",
            "service:order-service");
        
        // Record processing time
        statsd.recordExecutionTime("order.processing.time",
            order.getProcessingTimeMs(),
            "env:production",
            "service:order-service");
    }
    
    /**
     * Publishes order failure metrics to Datadog
     */
    public void recordOrderFailure(OrderRequest request, Exception error) {
        // Increment failure counter
        statsd.incrementCounter("order.failure.count",
            "env:production",
            "service:order-service",
            "error_type:" + error.getClass().getSimpleName());
        
        // Increment total counter
        statsd.incrementCounter("order.total.count",
            "env:production",
            "service:order-service");
        
        // Increment specific error counters
        if (error instanceof PaymentGatewayException) {
            statsd.incrementCounter("order.payment.timeout.count",
                "env:production",
                "service:order-service");
        } else if (error instanceof DatabaseException) {
            statsd.incrementCounter("order.database.error.count",
                "env:production",
                "service:order-service");
        } else if (error instanceof InventoryException) {
            statsd.incrementCounter("order.inventory.error.count",
                "env:production",
                "service:order-service");
        }
    }
    
    /**
     * Publishes order success rate (calculated metric)
     */
    @Scheduled(fixedRate = 60000) // Every minute
    public void publishSuccessRate() {
        // This is calculated in Datadog using:
        // (sum:order.success.count / sum:order.total.count) * 100
        
        // But we can also publish it directly for real-time monitoring
        double successRate = calculateSuccessRate();
        statsd.recordGaugeValue("order.success.rate",
            successRate,
            "env:production",
            "service:order-service");
    }
    
    private double calculateSuccessRate() {
        // Implementation to calculate from recent metrics
        // This is a simplified example
        return metricsRepository.getSuccessRateLastMinute();
    }
}
```

### Datadog Monitor Configuration

**Monitor Query:**
```
avg(last_10m):( 
  sum:order.success.count{env:production,service:order-service}.as_count() / 
  sum:order.total.count{env:production,service:order-service}.as_count() 
) * 100 < 75
```

**Monitor Settings:**
```yaml
name: "[P2] Order Success Rate < 75%"
type: metric alert
query: "avg(last_10m):(sum:order.success.count{env:production,service:order-service}.as_count() / sum:order.total.count{env:production,service:order-service}.as_count()) * 100 < 75"
message: |
  Order success rate has dropped below 75%
  
  Current value: {{value}}%
  Threshold: 75%
  
  Check the order-service for:
  - Payment gateway timeouts
  - Database connection issues
  - Inventory service availability
  
  @slack-alerts @pagerduty-oncall
thresholds:
  critical: 60
  warning: 75
  recovery: 80
evaluation_delay: 60
notify_no_data: true
no_data_timeframe: 10
tags:
  - env:production
  - service:order-service
  - team:platform
  - metric:order.success.rate
```

### Sample Datadog Metrics Dashboard

**Dashboard Widgets:**

```json
{
  "title": "Order Service - Success Rate Monitoring",
  "widgets": [
    {
      "definition": {
        "type": "timeseries",
        "requests": [
          {
            "q": "(sum:order.success.count{env:production}.as_count() / sum:order.total.count{env:production}.as_count()) * 100",
            "display_type": "line",
            "style": {
              "palette": "dog_classic",
              "line_type": "solid",
              "line_width": "normal"
            }
          }
        ],
        "title": "Order Success Rate (%)",
        "markers": [
          {
            "value": "y = 75",
            "display_type": "error dashed"
          }
        ]
      }
    },
    {
      "definition": {
        "type": "query_value",
        "requests": [
          {
            "q": "(sum:order.success.count{env:production}.as_count() / sum:order.total.count{env:production}.as_count()) * 100",
            "aggregator": "avg"
          }
        ],
        "title": "Current Success Rate",
        "precision": 2
      }
    },
    {
      "definition": {
        "type": "timeseries",
        "requests": [
          {
            "q": "sum:order.failure.count{env:production} by {error_type}.as_count()",
            "display_type": "bars",
            "style": {
              "palette": "warm"
            }
          }
        ],
        "title": "Order Failures by Error Type"
      }
    },
    {
      "definition": {
        "type": "toplist",
        "requests": [
          {
            "q": "top(sum:order.failure.count{env:production} by {error_type}.as_count(), 10, 'sum', 'desc')"
          }
        ],
        "title": "Top Error Types"
      }
    }
  ]
}
```

### Application Code Integration

**File: `src/main/java/com/company/order/service/OrderService.java`**

```java
@Service
public class OrderService {
    
    private final OrderRepository orderRepository;
    private final PaymentService paymentService;
    private final OrderMetricsPublisher metricsPublisher;
    
    @Autowired
    public OrderService(OrderRepository orderRepository,
                       PaymentService paymentService,
                       OrderMetricsPublisher metricsPublisher) {
        this.orderRepository = orderRepository;
        this.paymentService = paymentService;
        this.metricsPublisher = metricsPublisher;
    }
    
    public Order createOrder(OrderRequest request) {
        long startTime = System.currentTimeMillis();
        
        try {
            validateOrder(request);
            Order order = buildOrder(request);
            
            // Process payment
            PaymentResult payment = processPayment(request, order);
            order.setPaymentId(payment.getId());
            
            // Save order
            Order savedOrder = orderRepository.save(order);
            
            // Calculate processing time
            long processingTime = System.currentTimeMillis() - startTime;
            savedOrder.setProcessingTimeMs(processingTime);
            
            // Publish success metrics to Datadog
            metricsPublisher.recordOrderSuccess(savedOrder);
            
            log.info("Order created successfully: {}", savedOrder.getId());
            return savedOrder;
            
        } catch (PaymentGatewayException e) {
            log.error("Payment gateway error for order request", e);
            metricsPublisher.recordOrderFailure(request, e);
            throw e;
            
        } catch (DatabaseException e) {
            log.error("Database error while creating order", e);
            metricsPublisher.recordOrderFailure(request, e);
            throw e;
            
        } catch (InventoryException e) {
            log.error("Inventory service error for order request", e);
            metricsPublisher.recordOrderFailure(request, e);
            throw e;
            
        } catch (Exception e) {
            log.error("Unexpected error while creating order", e);
            metricsPublisher.recordOrderFailure(request, e);
            throw new OrderProcessingException("Failed to create order", e);
        }
    }
    
    private PaymentResult processPayment(OrderRequest request, Order order) {
        // Payment processing logic with metrics
        try {
            if (request.getPaymentMethodId() != null) {
                return processWithSavedPaymentMethod(request, order);
            } else {
                return processWithInlinePayment(request, order);
            }
        } catch (Exception e) {
            // Metrics are published in the calling method
            throw e;
        }
    }
}
```

### Sample Logs with Metric Publishing

```log
2025-11-21 20:40:15.123 INFO  [order-service] [trace-id: abc123] OrderController - Received order request for customer: cust_456
2025-11-21 20:40:15.134 INFO  [order-service] [trace-id: abc123] OrderService - Creating order with 2 items, total: $156.00
2025-11-21 20:40:15.145 INFO  [order-service] [trace-id: abc123] PaymentService - Processing payment via Stripe
2025-11-21 20:40:18.678 ERROR [order-service] [trace-id: abc123] PaymentService - Payment gateway timeout after 3500ms
2025-11-21 20:40:18.679 ERROR [order-service] [trace-id: abc123] OrderService - Payment gateway error for order request
2025-11-21 20:40:18.680 INFO  [order-service] [trace-id: abc123] OrderMetricsPublisher - Publishing failure metric: order.failure.count, error_type:PaymentGatewayException
2025-11-21 20:40:18.681 INFO  [order-service] [trace-id: abc123] OrderMetricsPublisher - Publishing metric: order.payment.timeout.count
2025-11-21 20:40:18.682 INFO  [order-service] [trace-id: abc123] OrderMetricsPublisher - Publishing metric: order.total.count
2025-11-21 20:40:18.683 INFO  [order-service] [trace-id: abc123] HTTP Response: 500 Internal Server Error

2025-11-21 20:40:22.234 INFO  [order-service] [trace-id: def456] OrderController - Received order request for customer: cust_789
2025-11-21 20:40:22.245 INFO  [order-service] [trace-id: def456] OrderService - Creating order with 1 item, total: $45.00
2025-11-21 20:40:22.256 INFO  [order-service] [trace-id: def456] PaymentService - Processing payment via Stripe
2025-11-21 20:40:22.456 INFO  [order-service] [trace-id: def456] PaymentService - Payment successful: pay_xyz789
2025-11-21 20:40:22.467 INFO  [order-service] [trace-id: def456] OrderRepository - Order saved: order_abc789
2025-11-21 20:40:22.468 INFO  [order-service] [trace-id: def456] OrderMetricsPublisher - Publishing success metric: order.success.count, payment_method:stripe
2025-11-21 20:40:22.469 INFO  [order-service] [trace-id: def456] OrderMetricsPublisher - Publishing metric: order.total.count
2025-11-21 20:40:22.470 INFO  [order-service] [trace-id: def456] OrderMetricsPublisher - Publishing metric: order.amount, value:45.0
2025-11-21 20:40:22.471 INFO  [order-service] [trace-id: def456] OrderMetricsPublisher - Publishing metric: order.processing.time, value:226ms
2025-11-21 20:40:22.472 INFO  [order-service] [trace-id: def456] HTTP Response: 201 Created

2025-11-21 20:41:00.000 INFO  [order-service] OrderMetricsPublisher - Scheduled task: Publishing order.success.rate = 68.5%
2025-11-21 20:41:00.001 INFO  [order-service] OrderMetricsPublisher - Success rate below threshold (75%), current: 68.5%

2025-11-21 20:42:00.000 INFO  [order-service] OrderMetricsPublisher - Scheduled task: Publishing order.success.rate = 67.2%
2025-11-21 20:42:00.001 WARN  [order-service] OrderMetricsPublisher - Success rate continuing to decline: 67.2%

2025-11-21 20:45:00.000 INFO  [order-service] OrderMetricsPublisher - Scheduled task: Publishing order.success.rate = 68.5%
2025-11-21 20:45:00.001 ERROR [order-service] AlertManager - Datadog monitor triggered: Order Success Rate < 75%
```

---

## Alert 15: Datadog Metric Alert - Item Export Failure Rate - HIGH

```
🟠 *Triggered: Item export to PA failure - smfe - us-east-1* - smb - multicustomer*

*Monitor:* Item export to PA failure > 25.0
*Status:* ALERT
*Service:* smfe
*Region:* us-east-1*
*Customer:* multicustomer | *Tier:* smb

*Metric Value:* 45.0%

*Query:*
```
sum(last_1h):sum:smarsh.cc.export.monitoring.parameters.items{customer:multicustomer,tier:smb,cloud_region:us-east-1*,service:smfe,status:error} by {feedexternalid,platform}.as_count() * 100 / sum:smarsh.cc.export.monitoring.parameters.items{customer:multicustomer,tier:smb,cloud_region:us-east-1*,service:smfe,status:success} by {feedexternalid,platform}.as_count() > 25
```

*Important link for debugging:*
- Traces: https://app.datadoghq.com/apm/traces

*Notify:* @slack-cc-smb-alerts

*Tags:*
`feedexternalid:00000000-0000-0000-0000-000000034678` `platform:k8s`
```

---

## Alert 16: Datadog Metric Alert - Content Processing Failure - CRITICAL

```
🔴 *Triggered: Content processing failure rate - dnse - us-west-2 - enterprise - client-abc*

*Monitor:* Content processing failure > 15.0
*Status:* ALERT
*Service:* dnse
*Region:* us-west-2
*Customer:* client-abc | *Tier:* enterprise

*Metric Value:* 28.5%

*Query:*
```
sum(last_30m):sum:smarsh.cc.content.processing.items{customer:client-abc,tier:enterprise,cloud_region:us-west-2,service:dnse,status:failed} by {contenttype,source}.as_count() * 100 / sum:smarsh.cc.content.processing.items{customer:client-abc,tier:enterprise,cloud_region:us-west-2,service:dnse,status:processed} by {contenttype,source}.as_count() > 15
```

*Important link for debugging:*
- Traces: https://app.datadoghq.com/apm/traces

*Notify:* @slack-cc-enterprise-alerts

*Tags:*
`contenttype:email` `source:exchange`
```

---

## Alert 17: Datadog Metric Alert - Export Latency Threshold Exceeded - HIGH

```
🟠 *Triggered: Export latency threshold exceeded - smfe - eu-central-1 - premium - client-xyz*

*Monitor:* Export latency p95 > 5000ms
*Status:* ALERT
*Service:* smfe
*Region:* eu-central-1
*Customer:* client-xyz | *Tier:* premium

*Metric Value:* 7250ms

*Query:*
```
avg(last_15m):p95:smarsh.cc.export.latency.ms{customer:client-xyz,tier:premium,cloud_region:eu-central-1,service:smfe} by {feedexternalid,destination}.as_count() > 5000
```

*Important link for debugging:*
- Traces: https://app.datadoghq.com/apm/traces

*Notify:* @slack-cc-premium-alerts

*Tags:*
`feedexternalid:00000000-0000-0000-0000-000000056789` `destination:s3`
```

---

## Alert 18: Datadog Metric Alert - Message Ingestion Failure - CRITICAL

```
🔴 *Triggered: Message ingestion failure rate - capture-api - us-east-1 - smb - multicustomer*

*Monitor:* Message ingestion failure > 10.0
*Status:* ALERT
*Service:* capture-api
*Region:* us-east-1
*Customer:* multicustomer | *Tier:* smb

*Metric Value:* 22.3%

*Query:*
```
sum(last_1h):sum:smarsh.cc.ingestion.messages{customer:multicustomer,tier:smb,cloud_region:us-east-1,service:capture-api,status:failed} by {channel,connector}.as_count() * 100 / sum:smarsh.cc.ingestion.messages{customer:multicustomer,tier:smb,cloud_region:us-east-1,service:capture-api,status:success} by {channel,connector}.as_count() > 10
```

*Important link for debugging:*
- Traces: https://app.datadoghq.com/apm/traces

*Notify:* @slack-cc-smb-alerts

*Tags:*
`channel:slack` `connector:slack-enterprise-grid`
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

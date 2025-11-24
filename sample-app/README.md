# Order Service - Production Alert Testing

A Spring Boot microservice that simulates realistic production failures for testing alert workflows.

## Overview

This service simulates an e-commerce order processing system with intentional failure scenarios to generate production alerts for testing your n8n Slack alert analysis workflow.

## Features

- **Order Management**: Create and manage orders
- **Payment Processing**: Process payments with simulated gateway failures
- **Inventory Management**: Check product availability
- **Failure Simulation**: Randomly triggers production-like failures
- **Metrics Tracking**: Monitors request counts, error rates, and response times

## Simulated Failure Scenarios

### 1. Database Timeout (10% probability)
- Simulates slow queries exceeding 30s timeout
- Connection pool exhaustion
- **Error**: `DatabaseTimeoutException`

### 2. Database Connection Error (5% probability)
- Connection pool exhausted
- **Error**: `DatabaseTimeoutException`

### 3. Inventory Service Failure (8% probability)
- External service unavailable
- **Error**: `InventoryException`

### 4. Payment Gateway Timeout (15% probability)
- Stripe API not responding
- **Error**: `PaymentGatewayException`

### 5. Payment Declined (10% probability)
- Insufficient funds or card declined
- **Error**: `PaymentGatewayException`

### 6. Validation Errors
- Missing required fields
- **Error**: `ValidationException`

## Prerequisites

- Java 17 or higher
- Maven 3.6+

## Running the Application

```bash
# Build the application
mvn clean install

# Run the application
mvn spring-boot:run
```

The service will start on `http://localhost:8080`

## API Endpoints

### Health Check
```bash
GET http://localhost:8080/health
```

### Create Order (with random failures)
```bash
POST http://localhost:8080/api/orders
Content-Type: application/json

{
  "customerId": "CUST-001",
  "productId": "PROD-001",
  "quantity": 2,
  "totalAmount": 199.99
}
```

### Get Order
```bash
GET http://localhost:8080/api/orders/{orderId}
```

### Process Payment (with random failures)
```bash
POST http://localhost:8080/api/payment/process
Content-Type: application/json

{
  "orderId": "ORD-12345",
  "paymentMethod": "credit_card",
  "amount": 199.99
}
```

### Get Metrics
```bash
GET http://localhost:8080/api/metrics
```

### Get Inventory
```bash
GET http://localhost:8080/api/inventory
```

## Testing the Workflow

### Generate Load and Failures

Use the provided test script to generate traffic and trigger failures:

```bash
# Run multiple requests to trigger various failures
for i in {1..20}; do
  curl -X POST http://localhost:8080/api/orders \
    -H "Content-Type: application/json" \
    -d "{\"customerId\":\"CUST-$i\",\"productId\":\"PROD-001\",\"quantity\":1,\"totalAmount\":99.99}"
  sleep 1
done
```

## Sample Products

- `PROD-001`: Available (100 units)
- `PROD-002`: Available (50 units)
- `PROD-003`: Out of stock (0 units) - will trigger inventory error
- `PROD-004`: Available (25 units)
- `PROD-005`: Available (200 units)

## Monitoring

Check application metrics:
```bash
curl http://localhost:8080/api/metrics
```

Expected response:
```json
{
  "service": "order-service",
  "totalRequests": 150,
  "failedRequests": 45,
  "errorRate": "30.00%",
  "avgResponseTimeMs": "1250.50",
  "memoryUsageMb": 512,
  "timestamp": "2025-11-21T14:00:00"
}
```

## Integration with n8n Workflow

This service generates errors that should trigger Slack alerts. The alerts can then be analyzed by your n8n workflow for:

1. **Root Cause Analysis**: AI identifies the type of failure
2. **Impact Assessment**: Determines severity and affected services
3. **Remediation Steps**: Suggests fixes based on error type
4. **Historical Context**: Links to similar past incidents

## Architecture

```
OrderController
    ↓
OrderService (with failure simulation)
    ↓
OrderRepository (JPA/H2)
    ↓
GlobalExceptionHandler (formats errors)
```

## Next Steps

1. Start the application
2. Generate some traffic to trigger failures
3. Configure monitoring to send alerts to Slack
4. Test your n8n workflow with real alert messages

#!/bin/bash

# Test script to generate traffic and trigger failures in the order service
# This will help generate real alerts for testing your n8n workflow

BASE_URL="http://localhost:8080"
COLORS='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${COLORS}=== Order Service Load Test ===${NC}"
echo "This script will generate traffic to trigger various failure scenarios"
echo ""

# Check if service is running
echo "Checking if service is running..."
if ! curl -s "${BASE_URL}/health" > /dev/null; then
    echo "❌ Service is not running at ${BASE_URL}"
    echo "Please start the service first: mvn spring-boot:run"
    exit 1
fi

echo "✅ Service is running"
echo ""

# Function to create order
create_order() {
    local customer_id=$1
    local product_id=$2
    local quantity=$3
    local amount=$4
    
    curl -s -X POST "${BASE_URL}/api/orders" \
        -H "Content-Type: application/json" \
        -d "{
            \"customerId\": \"${customer_id}\",
            \"productId\": \"${product_id}\",
            \"quantity\": ${quantity},
            \"totalAmount\": ${amount}
        }" | jq -r '.orderId // .error // "Error"'
}

# Function to process payment
process_payment() {
    local order_id=$1
    local amount=$2
    
    curl -s -X POST "${BASE_URL}/api/payment/process" \
        -H "Content-Type: application/json" \
        -d "{
            \"orderId\": \"${order_id}\",
            \"paymentMethod\": \"credit_card\",
            \"amount\": ${amount}
        }" | jq -r '.status // .error // "Error"'
}

echo "=== Test 1: Normal Orders (will trigger random failures) ==="
echo "Creating 20 orders to trigger various failure scenarios..."
echo ""

for i in {1..20}; do
    echo -n "Request $i: "
    result=$(create_order "CUST-$(printf "%03d" $i)" "PROD-001" 1 99.99)
    echo "$result"
    sleep 0.5
done

echo ""
echo "=== Test 2: Out of Stock Product ==="
echo "Attempting to order out-of-stock product..."
result=$(create_order "CUST-999" "PROD-003" 1 49.99)
echo "Result: $result"
echo ""

echo "=== Test 3: Invalid Requests ==="
echo "Testing validation errors..."

# Missing customer ID
echo -n "Missing customer ID: "
curl -s -X POST "${BASE_URL}/api/orders" \
    -H "Content-Type: application/json" \
    -d '{"productId":"PROD-001","quantity":1,"totalAmount":99.99}' \
    | jq -r '.error // "Error"'

# Invalid quantity
echo -n "Invalid quantity: "
curl -s -X POST "${BASE_URL}/api/orders" \
    -H "Content-Type: application/json" \
    -d '{"customerId":"CUST-001","productId":"PROD-001","quantity":0,"totalAmount":99.99}' \
    | jq -r '.error // "Error"'

echo ""
echo "=== Test 4: Payment Processing (will trigger random failures) ==="
echo "Processing 10 payments..."
echo ""

for i in {1..10}; do
    echo -n "Payment $i: "
    result=$(process_payment "ORD-TEST-$i" 199.99)
    echo "$result"
    sleep 0.5
done

echo ""
echo "=== Test 5: High Load Test ==="
echo "Generating high load (50 concurrent requests)..."
echo ""

for i in {1..50}; do
    create_order "CUST-LOAD-$i" "PROD-001" 1 99.99 &
done

wait

echo ""
echo "=== Checking Metrics ==="
echo ""

curl -s "${BASE_URL}/api/metrics" | jq '.'

echo ""
echo "=== Test Complete ==="
echo ""
echo "Summary:"
echo "- Generated ~80 requests total"
echo "- Expected failures: ~20-30 (based on failure rates)"
echo "- Check application logs for error details"
echo "- Check Slack for alert messages"
echo ""
echo "To view detailed metrics:"
echo "  curl ${BASE_URL}/api/metrics | jq"
echo ""
echo "To check inventory:"
echo "  curl ${BASE_URL}/api/inventory | jq"

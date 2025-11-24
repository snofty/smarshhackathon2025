package com.example.orderservice.service;

import com.example.orderservice.dto.PaymentRequest;
import com.example.orderservice.exception.OrderNotFoundException;
import com.example.orderservice.exception.PaymentGatewayException;
import com.example.orderservice.exception.ValidationException;
import com.example.orderservice.model.Order;
import com.example.orderservice.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
@Slf4j
public class PaymentService {
    
    private final OrderRepository orderRepository;
    private final MetricsService metricsService;
    private final Random random = new Random();
    
    @Transactional
    public Map<String, Object> processPayment(PaymentRequest request) {
        long startTime = System.currentTimeMillis();
        metricsService.incrementTotalRequests();
        
        try {
            // Validate payment request
            validatePaymentRequest(request);
            
            // Find order
            Order order = orderRepository.findByOrderId(request.getOrderId())
                .orElseThrow(() -> new OrderNotFoundException("Order not found: " + request.getOrderId()));
            
            // Simulate payment gateway failures
            simulatePaymentGatewayFailures(request);
            
            // Process payment
            String transactionId = "TXN-" + UUID.randomUUID().toString().substring(0, 12).toUpperCase();
            
            // Update order status
            order.setStatus(Order.OrderStatus.PAYMENT_COMPLETED);
            order.setUpdatedAt(LocalDateTime.now());
            orderRepository.save(order);
            
            log.info("Payment processed successfully for order: {}", request.getOrderId());
            metricsService.recordResponseTime(System.currentTimeMillis() - startTime);
            
            Map<String, Object> response = new HashMap<>();
            response.put("status", "success");
            response.put("transactionId", transactionId);
            response.put("orderId", request.getOrderId());
            response.put("amount", request.getAmount());
            response.put("timestamp", LocalDateTime.now());
            
            return response;
            
        } catch (Exception e) {
            metricsService.incrementFailedRequests();
            throw e;
        }
    }
    
    private void validatePaymentRequest(PaymentRequest request) {
        if (request.getOrderId() == null || request.getOrderId().isEmpty()) {
            throw new ValidationException("Order ID is required");
        }
        if (request.getAmount() == null || request.getAmount() <= 0) {
            throw new ValidationException("Payment amount must be greater than 0");
        }
        if (request.getPaymentMethod() == null || request.getPaymentMethod().isEmpty()) {
            throw new ValidationException("Payment method is required");
        }
    }
    
    /**
     * Simulates payment gateway failures
     */
    private void simulatePaymentGatewayFailures(PaymentRequest request) {
        int scenario = random.nextInt(100);
        
        // 15% chance of payment gateway timeout
        if (scenario < 15) {
            log.error("Simulating payment gateway timeout");
            try {
                TimeUnit.SECONDS.sleep(32); // Exceeds timeout
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            throw new PaymentGatewayException(
                "Payment gateway timeout - Stripe API not responding after 30s"
            );
        }
        
        // 10% chance of payment declined
        if (scenario >= 15 && scenario < 25) {
            log.error("Simulating payment declined");
            throw new PaymentGatewayException(
                "Payment declined by gateway - Insufficient funds or card declined"
            );
        }
        
        // 5% chance of payment gateway service unavailable
        if (scenario >= 25 && scenario < 30) {
            log.error("Simulating payment gateway service unavailable");
            throw new PaymentGatewayException(
                "Payment gateway service unavailable - HTTP 503 from api.stripe.com"
            );
        }
    }
}

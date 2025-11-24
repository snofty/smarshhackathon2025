package com.example.orderservice.service;

import com.example.orderservice.dto.OrderRequest;
import com.example.orderservice.dto.OrderResponse;
import com.example.orderservice.exception.*;
import com.example.orderservice.model.Order;
import com.example.orderservice.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Random;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
@Slf4j
public class OrderService {
    
    private final OrderRepository orderRepository;
    private final InventoryService inventoryService;
    private final MetricsService metricsService;
    private final Random random = new Random();
    
    @Transactional
    public OrderResponse createOrder(OrderRequest request) {
        long startTime = System.currentTimeMillis();
        metricsService.incrementTotalRequests();
        
        try {
            // Validate request
            validateOrderRequest(request);
            
            // Simulate various production failures
            simulateProductionFailures(request);
            
            // Check inventory
            if (!inventoryService.checkAvailability(request.getProductId(), request.getQuantity())) {
                throw new InventoryException(
                    String.format("Product %s is out of stock or insufficient quantity", 
                        request.getProductId())
                );
            }
            
            // Create order
            Order order = Order.builder()
                .orderId("ORD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                .customerId(request.getCustomerId())
                .productId(request.getProductId())
                .quantity(request.getQuantity())
                .totalAmount(request.getTotalAmount())
                .status(Order.OrderStatus.CREATED)
                .createdAt(LocalDateTime.now())
                .build();
            
            order = orderRepository.save(order);
            
            log.info("Order created successfully: {}", order.getOrderId());
            metricsService.recordResponseTime(System.currentTimeMillis() - startTime);
            
            return mapToResponse(order);
            
        } catch (Exception e) {
            metricsService.incrementFailedRequests();
            throw e;
        }
    }
    
    public OrderResponse getOrder(String orderId) {
        Order order = orderRepository.findByOrderId(orderId)
            .orElseThrow(() -> new OrderNotFoundException("Order not found: " + orderId));
        return mapToResponse(order);
    }
    
    @Transactional
    public OrderResponse updateOrderStatus(String orderId, Order.OrderStatus status) {
        Order order = orderRepository.findByOrderId(orderId)
            .orElseThrow(() -> new OrderNotFoundException("Order not found: " + orderId));
        
        order.setStatus(status);
        order.setUpdatedAt(LocalDateTime.now());
        order = orderRepository.save(order);
        
        log.info("Order {} status updated to {}", orderId, status);
        return mapToResponse(order);
    }
    
    private void validateOrderRequest(OrderRequest request) {
        if (request.getCustomerId() == null || request.getCustomerId().isEmpty()) {
            throw new ValidationException("Customer ID is required");
        }
        if (request.getProductId() == null || request.getProductId().isEmpty()) {
            throw new ValidationException("Product ID is required");
        }
        if (request.getQuantity() == null || request.getQuantity() <= 0) {
            throw new ValidationException("Quantity must be greater than 0");
        }
        if (request.getTotalAmount() == null || request.getTotalAmount() <= 0) {
            throw new ValidationException("Total amount must be greater than 0");
        }
    }
    
    /**
     * Simulates various production failure scenarios for testing
     */
    private void simulateProductionFailures(OrderRequest request) {
        int scenario = random.nextInt(100);
        
        // 10% chance of database timeout
        if (scenario < 10) {
            log.error("Simulating database timeout");
            try {
                TimeUnit.SECONDS.sleep(35); // Exceeds typical timeout
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            throw new DatabaseTimeoutException(
                "Database query timeout after 30s - Connection pool exhausted (10/10 connections in use)"
            );
        }
        
        // 5% chance of database connection error
        if (scenario >= 10 && scenario < 15) {
            log.error("Simulating database connection error");
            throw new DatabaseTimeoutException(
                "Failed to acquire database connection from pool - HikariPool exhausted"
            );
        }
        
        // 8% chance of inventory service failure
        if (scenario >= 15 && scenario < 23) {
            log.error("Simulating inventory service failure");
            throw new InventoryException(
                "Inventory service unavailable - HTTP 503 from inventory-service.prod.internal:8080"
            );
        }
    }
    
    private OrderResponse mapToResponse(Order order) {
        return OrderResponse.builder()
            .orderId(order.getOrderId())
            .customerId(order.getCustomerId())
            .productId(order.getProductId())
            .quantity(order.getQuantity())
            .totalAmount(order.getTotalAmount())
            .status(order.getStatus().name())
            .createdAt(order.getCreatedAt())
            .build();
    }
}

package com.example.orderservice.controller;

import com.example.orderservice.service.InventoryService;
import com.example.orderservice.service.MetricsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequiredArgsConstructor
public class HealthController {
    
    private final MetricsService metricsService;
    private final InventoryService inventoryService;
    
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> health = new HashMap<>();
        health.put("status", "UP");
        health.put("service", "order-service");
        health.put("version", "1.2.3");
        health.put("timestamp", LocalDateTime.now());
        return ResponseEntity.ok(health);
    }
    
    @GetMapping("/api/metrics")
    public ResponseEntity<Map<String, Object>> metrics() {
        metricsService.simulateMemoryLeak();
        
        Map<String, Object> metrics = new HashMap<>();
        metrics.put("service", "order-service");
        metrics.put("totalRequests", metricsService.getTotalRequests().get());
        metrics.put("failedRequests", metricsService.getFailedRequests().get());
        metrics.put("errorRate", String.format("%.2f%%", metricsService.getErrorRate()));
        metrics.put("avgResponseTimeMs", String.format("%.2f", metricsService.getAverageResponseTime()));
        metrics.put("memoryUsageMb", metricsService.getMemoryUsageMb().get());
        metrics.put("timestamp", LocalDateTime.now());
        
        return ResponseEntity.ok(metrics);
    }
    
    @GetMapping("/api/inventory")
    public ResponseEntity<Map<String, Integer>> inventory() {
        return ResponseEntity.ok(inventoryService.getAllInventory());
    }
}

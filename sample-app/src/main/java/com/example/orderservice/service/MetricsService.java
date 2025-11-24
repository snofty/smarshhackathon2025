package com.example.orderservice.service;

import lombok.Getter;
import org.springframework.stereotype.Service;

import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;

@Service
@Getter
public class MetricsService {
    
    private final AtomicLong totalRequests = new AtomicLong(0);
    private final AtomicLong failedRequests = new AtomicLong(0);
    private final AtomicLong totalResponseTime = new AtomicLong(0);
    private final AtomicInteger memoryUsageMb = new AtomicInteger(256);
    
    public void incrementTotalRequests() {
        totalRequests.incrementAndGet();
    }
    
    public void incrementFailedRequests() {
        failedRequests.incrementAndGet();
    }
    
    public void recordResponseTime(long responseTime) {
        totalResponseTime.addAndGet(responseTime);
    }
    
    public double getAverageResponseTime() {
        long total = totalRequests.get();
        return total > 0 ? (double) totalResponseTime.get() / total : 0;
    }
    
    public double getErrorRate() {
        long total = totalRequests.get();
        return total > 0 ? (double) failedRequests.get() / total * 100 : 0;
    }
    
    public void simulateMemoryLeak() {
        // Simulate gradual memory increase
        memoryUsageMb.addAndGet((int) (Math.random() * 10));
    }
}

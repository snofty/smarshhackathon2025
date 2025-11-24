package com.example.orderservice.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
@Slf4j
public class InventoryService {
    
    private final Map<String, Integer> inventory = new HashMap<>();
    
    public InventoryService() {
        // Initialize with sample inventory
        inventory.put("PROD-001", 100);
        inventory.put("PROD-002", 50);
        inventory.put("PROD-003", 0);  // Out of stock
        inventory.put("PROD-004", 25);
        inventory.put("PROD-005", 200);
    }
    
    public boolean checkAvailability(String productId, int quantity) {
        int available = inventory.getOrDefault(productId, 0);
        log.info("Checking inventory for product: {} - Available: {}, Requested: {}", 
            productId, available, quantity);
        return available >= quantity;
    }
    
    public void updateInventory(String productId, int quantity) {
        int current = inventory.getOrDefault(productId, 0);
        inventory.put(productId, current + quantity);
        log.info("Inventory updated for product: {} - New quantity: {}", productId, current + quantity);
    }
    
    public Map<String, Integer> getAllInventory() {
        return new HashMap<>(inventory);
    }
}

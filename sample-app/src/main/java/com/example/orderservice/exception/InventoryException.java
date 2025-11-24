package com.example.orderservice.exception;

public class InventoryException extends RuntimeException {
    public InventoryException(String message) {
        super(message);
    }
}

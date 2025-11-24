package com.example.orderservice.controller;

import com.example.orderservice.dto.PaymentRequest;
import com.example.orderservice.service.PaymentService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/payment")
@RequiredArgsConstructor
@Slf4j
public class PaymentController {
    
    private final PaymentService paymentService;
    
    @PostMapping("/process")
    public ResponseEntity<Map<String, Object>> processPayment(@RequestBody PaymentRequest request) {
        log.info("Processing payment for order: {}", request.getOrderId());
        Map<String, Object> response = paymentService.processPayment(request);
        return ResponseEntity.ok(response);
    }
}

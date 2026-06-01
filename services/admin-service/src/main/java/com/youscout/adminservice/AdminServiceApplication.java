package com.youscout.adminservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@SpringBootApplication
@RestController
public class AdminServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(AdminServiceApplication.class, args);
    }

    @GetMapping("/admin/health")
    public Map<String, String> health() {
        return Map.of("status", "UP", "service", "admin-service", "note", "Stub only for MVP");
    }
}

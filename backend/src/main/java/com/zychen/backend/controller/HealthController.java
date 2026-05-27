package com.zychen.backend.controller;

import com.zychen.backend.dto.response.HealthResponse;
import com.zychen.backend.service.HealthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 容器编排健康探测（Docker HEALTHCHECK、负载均衡等），与业务 JWT 路径隔离（非 /api/**）。
 */
@RestController
@RequiredArgsConstructor
public class HealthController {

    private final HealthService healthService;

    @GetMapping(value = "/health", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<HealthResponse> health() {
        HealthResponse body = healthService.checkHealth();
        if ("healthy".equals(body.getStatus())) {
            return ResponseEntity.ok(body);
        }
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(body);
    }
}

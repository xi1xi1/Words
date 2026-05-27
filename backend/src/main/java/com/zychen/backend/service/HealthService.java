package com.zychen.backend.service;

import com.zychen.backend.dto.response.HealthResponse;

public interface HealthService {

    HealthResponse checkHealth();

    boolean isHealthy();
}

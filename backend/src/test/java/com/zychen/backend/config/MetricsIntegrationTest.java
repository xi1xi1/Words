package com.zychen.backend.config;

import io.micrometer.core.instrument.MeterRegistry;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class MetricsIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private MeterRegistry meterRegistry;

    @Test
    void healthRequest_incrementsHttpMetrics() throws Exception {
        mockMvc.perform(get("/health")).andExpect(status().isOk());

        assertTrue(meterRegistry.counter(RequestMetricsFilter.METRIC_REQUESTS).count() >= 1.0);
    }

    @Test
    void actuatorMetrics_exposesCustomMetricDetails() throws Exception {
        mockMvc.perform(get("/health"));

        mockMvc.perform(get("/actuator/metrics/beileme.http.requests"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("beileme.http.requests"))
                .andExpect(jsonPath("$.measurements[0].value").isNumber());

        mockMvc.perform(get("/actuator/metrics/beileme.http.request.duration"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("beileme.http.request.duration"));

        // errors 计数器仅在首次 4xx/5xx 后才注册，先触发一次 401
        mockMvc.perform(get("/api/words/daily"))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(get("/actuator/metrics/beileme.http.errors"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("beileme.http.errors"))
                .andExpect(jsonPath("$.measurements[0].value").value(greaterThanOrEqualTo(1.0)));

        mockMvc.perform(get("/actuator/metrics/beileme.active.users"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("beileme.active.users"));
    }
}

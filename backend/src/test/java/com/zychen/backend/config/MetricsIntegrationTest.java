package com.zychen.backend.config;

import io.micrometer.core.instrument.MeterRegistry;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

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
        double requestsBefore = meterRegistry.get(RequestMetricsFilter.METRIC_REQUESTS).counter().count();

        mockMvc.perform(get("/health")).andExpect(status().isOk());

        double requestsAfter = meterRegistry.get(RequestMetricsFilter.METRIC_REQUESTS).counter().count();
        assertTrue(requestsAfter > requestsBefore);
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

        mockMvc.perform(get("/actuator/metrics/beileme.http.errors"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("beileme.http.errors"));

        mockMvc.perform(get("/actuator/metrics/beileme.active.users"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("beileme.active.users"));
    }
}

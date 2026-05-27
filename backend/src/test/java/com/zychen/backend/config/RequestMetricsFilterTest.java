package com.zychen.backend.config;

import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RequestMetricsFilterTest {

    private MeterRegistry meterRegistry;
    private ActiveUsersTracker activeUsersTracker;
    private RequestMetricsFilter filter;

    @BeforeEach
    void setUp() {
        meterRegistry = new SimpleMeterRegistry();
        activeUsersTracker = new ActiveUsersTracker();
        filter = new RequestMetricsFilter(meterRegistry, activeUsersTracker);
    }

    @Test
    void doFilter_success_incrementsRequestAndDuration() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/health");
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(request, response, chain);

        assertEquals(1.0, meterRegistry.counter(RequestMetricsFilter.METRIC_REQUESTS).count());
        assertTrue(meterRegistry.timer(RequestMetricsFilter.METRIC_DURATION).count() > 0);
        // 未发生错误时 errors 计数器可能尚未注册，用 counter() 获取或创建后应为 0
        assertEquals(0.0, meterRegistry.counter(RequestMetricsFilter.METRIC_ERRORS).count());
    }

    @Test
    void doFilter_errorStatus_incrementsErrorCounter() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/words/daily");
        MockHttpServletResponse response = new MockHttpServletResponse();
        response.setStatus(401);
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(request, response, chain);

        assertEquals(1.0, meterRegistry.counter(RequestMetricsFilter.METRIC_ERRORS).count());
    }

    @Test
    void doFilter_authenticatedUser_recordsActiveUser() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/study/stats");
        request.setAttribute("userId", 42L);
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(request, response, chain);

        assertEquals(1.0, activeUsersTracker.countActiveUsers());
    }

    @Test
    void shouldNotFilter_actuatorPath() {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/actuator/metrics");
        assertTrue(filter.shouldNotFilter(request));
    }
}

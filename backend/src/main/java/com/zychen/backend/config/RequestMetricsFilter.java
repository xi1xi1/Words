package com.zychen.backend.config;

import io.micrometer.core.instrument.MeterRegistry;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.concurrent.TimeUnit;

/**
 * 收集 HTTP 请求计数、响应耗时与错误率（4xx/5xx），写入 Micrometer 供 Actuator 查询。
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 20)
public class RequestMetricsFilter extends OncePerRequestFilter {

    static final String METRIC_REQUESTS = "beileme.http.requests";
    static final String METRIC_DURATION = "beileme.http.request.duration";
    static final String METRIC_ERRORS = "beileme.http.errors";

    private final MeterRegistry meterRegistry;
    private final ActiveUsersTracker activeUsersTracker;

    public RequestMetricsFilter(MeterRegistry meterRegistry, ActiveUsersTracker activeUsersTracker) {
        this.meterRegistry = meterRegistry;
        this.activeUsersTracker = activeUsersTracker;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return resolvePath(request).startsWith("/actuator");
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain) throws ServletException, IOException {
        long startNanos = System.nanoTime();
        try {
            filterChain.doFilter(request, response);
        } finally {
            recordMetrics(request, response, System.nanoTime() - startNanos);
        }
    }

    private void recordMetrics(HttpServletRequest request, HttpServletResponse response, long durationNanos) {
        meterRegistry.counter(METRIC_REQUESTS).increment();
        meterRegistry.timer(METRIC_DURATION).record(durationNanos, TimeUnit.NANOSECONDS);

        if (response.getStatus() >= 400) {
            meterRegistry.counter(METRIC_ERRORS).increment();
        }

        Object userId = request.getAttribute("userId");
        if (userId instanceof Long id) {
            activeUsersTracker.recordUser(id);
        }
    }

    private String resolvePath(HttpServletRequest request) {
        String path = request.getServletPath();
        if (path == null || path.isEmpty()) {
            path = request.getRequestURI();
        }
        return path;
    }
}

package com.zychen.backend.config;

import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * 注册自定义 Micrometer 指标（活跃用户数等）。
 */
@Configuration
public class MetricsConfig {

    @Bean
    Gauge activeUsersGauge(MeterRegistry registry, ActiveUsersTracker activeUsersTracker) {
        return Gauge.builder("beileme.active.users", activeUsersTracker, ActiveUsersTracker::countActiveUsers)
                .description("近 15 分钟内有已认证请求的去重用户数")
                .register(registry);
    }
}

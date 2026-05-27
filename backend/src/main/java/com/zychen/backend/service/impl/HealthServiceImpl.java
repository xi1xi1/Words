package com.zychen.backend.service.impl;

import com.zychen.backend.dto.response.HealthResponse;
import com.zychen.backend.service.HealthService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.sql.Connection;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;

@Slf4j
@Service
@RequiredArgsConstructor
public class HealthServiceImpl implements HealthService {

    private static final String STATUS_HEALTHY = "healthy";
    private static final String STATUS_UNHEALTHY = "unhealthy";
    private static final String DB_UP = "up";
    private static final String DB_DOWN = "down";
    private static final int DB_VALIDATION_TIMEOUT_SECONDS = 2;
    private static final ZoneId ZONE = ZoneId.of("Asia/Shanghai");
    private static final DateTimeFormatter ISO_FORMATTER = DateTimeFormatter.ISO_OFFSET_DATE_TIME;

    @Value("${app.version:0.0.1-SNAPSHOT}")
    private String appVersion;

    private final DataSource dataSource;

    @Override
    public HealthResponse checkHealth() {
        boolean dbUp = isDatabaseUp();
        String status = dbUp ? STATUS_HEALTHY : STATUS_UNHEALTHY;
        String timestamp = ZonedDateTime.now(ZONE).format(ISO_FORMATTER);
        return new HealthResponse(
                status, timestamp, appVersion, dbUp ? DB_UP : DB_DOWN);
    }

    @Override
    public boolean isHealthy() {
        return isDatabaseUp();
    }

    private boolean isDatabaseUp() {
        try (Connection connection = dataSource.getConnection()) {
            return connection.isValid(DB_VALIDATION_TIMEOUT_SECONDS);
        } catch (Exception e) {
            log.warn("数据库健康检查失败: {}", e.getMessage());
            return false;
        }
    }
}

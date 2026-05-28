package com.zychen.backend.service.impl;

import com.zychen.backend.dto.response.HealthResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import javax.sql.DataSource;
import java.sql.Connection;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class HealthServiceImplTest {

    private final DataSource dataSource = mock(DataSource.class);
    private final HealthServiceImpl healthService = new HealthServiceImpl(dataSource);

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(healthService, "appVersion", "0.0.1-SNAPSHOT");
    }

    @Test
    void checkHealth_databaseUp_returnsHealthy() throws Exception {
        Connection connection = mock(Connection.class);
        when(dataSource.getConnection()).thenReturn(connection);
        when(connection.isValid(2)).thenReturn(true);

        HealthResponse response = healthService.checkHealth();

        assertEquals("healthy", response.getStatus());
        assertEquals("0.0.1-SNAPSHOT", response.getVersion());
        assertEquals("up", response.getDatabase());
        assertTrue(response.getTimestamp() != null && !response.getTimestamp().isBlank());
        assertTrue(healthService.isHealthy());
    }

    @Test
    void checkHealth_databaseDown_returnsUnhealthy() throws Exception {
        when(dataSource.getConnection()).thenThrow(new RuntimeException("connection refused"));

        HealthResponse response = healthService.checkHealth();

        assertEquals("unhealthy", response.getStatus());
        assertEquals("down", response.getDatabase());
        assertFalse(healthService.isHealthy());
    }
}

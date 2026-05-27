package com.zychen.backend.config;

import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 统计时间窗口内有过已认证请求的去重用户数（可选监控指标）。
 */
@Component
public class ActiveUsersTracker {

    private static final Duration DEFAULT_WINDOW = Duration.ofMinutes(15);

    private final Map<Long, Instant> lastSeenByUser = new ConcurrentHashMap<>();

    public void recordUser(Long userId) {
        if (userId != null) {
            lastSeenByUser.put(userId, Instant.now());
        }
    }

    public double countActiveUsers() {
        return countActiveUsers(DEFAULT_WINDOW);
    }

    public double countActiveUsers(Duration window) {
        Instant cutoff = Instant.now().minus(window);
        lastSeenByUser.entrySet().removeIf(entry -> entry.getValue().isBefore(cutoff));
        return lastSeenByUser.size();
    }
}

package com.zychen.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * GET /health 响应体（与业务 ApiResponse 分离，供负载均衡与容器探针使用）。
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class HealthResponse {

    /** healthy / unhealthy */
    private String status;

    /** ISO-8601 时间戳 */
    private String timestamp;

    /** 应用版本，来自 app.version */
    private String version;

    /** 数据库探针：up / down */
    private String database;
}

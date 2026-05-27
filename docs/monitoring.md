# 背了么 — 监控与可观测性说明

本文档说明 **「背了么」** 后端（Spring Boot 3.5 + Java 17）的监控配置：结构化日志、健康检查、基础指标，以及本地/线上如何查看。实现与仓库内 `backend/` 代码一致。

---

## 1. 概览

| 能力 | 实现方式 | 主要文件 |
|------|----------|----------|
| 结构化日志 | Logback + `logstash-logback-encoder`（JSON 一行一条） | `backend/src/main/resources/logback-spring.xml` |
| 健康检查 | `GET /health`（含数据库探针） | `HealthController`、`HealthServiceImpl` |
| 请求指标 | Micrometer + `RequestMetricsFilter` | `RequestMetricsFilter`、`MetricsConfig` |
| 指标查询 | Spring Boot Actuator `metrics` | `backend/src/main/resources/application.properties` |
| 活跃用户（可选） | `ActiveUsersTracker` + Gauge | `ActiveUsersTracker`、`MetricsConfig` |

**设计原则：**

- `/health` 与业务 API（`/api/**`）分离，**无需 JWT**，供 Docker / Railway / 负载均衡探活。
- `/actuator/**` 默认不纳入请求指标统计，避免探针请求干扰业务指标。
- 生产环境勿将 `/actuator` 无限制暴露到公网；日志中勿输出密码、Token 等敏感信息。

---

## 2. 架构关系

```
HTTP 请求
    │
    ▼
┌─────────────────────────────────────┐
│  RequestMetricsFilter               │  ← 计数 / 耗时 / 错误 / 活跃用户
│  （跳过 /actuator/**）               │
└──────────────┬──────────────────────┘
               │
    ┌──────────┴──────────┐
    ▼                     ▼
GET /health          GET /api/**
（HealthController）  （JWT + 业务）
    │                     │
    ▼                     ▼
数据库 isValid(2s)     业务逻辑 + @Slf4j 日志
    │
    ▼
JSON 日志 → 控制台 + backend/logs/app.log
    │
    ▼
Micrometer → GET /actuator/metrics
```

---

## 3. 结构化日志

### 3.1 依赖与配置

- **Maven 依赖：** `net.logstash.logback:logstash-logback-encoder`（见 `backend/pom.xml`）
- **Logback 配置：** `backend/src/main/resources/logback-spring.xml`
- **日志级别：** `backend/src/main/resources/application.yml` 中 `logging.level.*`

### 3.2 输出字段

每条日志为一行 JSON，字段与课程要求对应如下：

| 课程字段 | JSON 字段 | 说明 |
|----------|-----------|------|
| `time` | `time` | ISO-8601 时间戳 |
| `level` | `level` | 如 `INFO`、`WARN`、`ERROR` |
| `message` | `message` | 日志正文 |
| `module` | `module` | 来源 Logger（类名） |
| — | `app` | 应用名，固定为 `beileme-backend` |

### 3.3 输出位置

| 目标 | 路径 / 说明 |
|------|-------------|
| 控制台 | 启动进程的标准输出（Docker / Railway 日志面板可见） |
| 文件 | `backend/logs/app.log`（滚动：单文件 10MB，保留 7 天，总量上限约 100MB） |

> `logs/` 已在根目录 `.gitignore` 中忽略，不会提交到 Git。

### 3.4 示例

```json
{"time":"2026-05-27T14:30:00.123+08:00","level":"INFO","message":"Started BackendApplication in 3.2 seconds","module":"com.zychen.backend.BackendApplication","app":"beileme-backend"}
```

### 3.5 调整日志级别

在 `application.yml` 或环境变量中设置，例如：

```yaml
logging:
  level:
    root: INFO
    com.zychen.backend: DEBUG   # 开发可 DEBUG，生产建议 INFO
```

---

## 4. 健康检查

### 4.1 端点

| 项目 | 说明 |
|------|------|
| **URL** | `GET /health` |
| **认证** | 不需要 |
| **Content-Type** | `application/json` |

与 Spring Actuator 的 `/actuator/health` **并存**；Docker `HEALTHCHECK` 与 Compose 使用 **`/health`**。

### 4.2 检查逻辑

`HealthServiceImpl` 执行：

1. 从数据源获取连接，`connection.isValid(2)` 探测 MySQL（超时 2 秒）。
2. 数据库可用 → `status: healthy`，`database: up`；否则 → `status: unhealthy`，`database: down`。
3. 附带 `timestamp`（Asia/Shanghai，ISO-8601）与 `version`（配置项 `app.version`）。

### 4.3 响应示例

**健康（HTTP 200）：**

```json
{
  "status": "healthy",
  "timestamp": "2026-05-27T14:30:00+08:00",
  "version": "0.0.1-SNAPSHOT",
  "database": "up"
}
```

**不健康（HTTP 503）：**

```json
{
  "status": "unhealthy",
  "timestamp": "2026-05-27T14:30:00+08:00",
  "version": "0.0.1-SNAPSHOT",
  "database": "down"
}
```

数据库失败时会在日志中输出 `WARN`：`数据库健康检查失败: ...`（结构化 JSON 格式）。

### 4.4 版本号配置

```yaml
# application.yml
app:
  version: 0.0.1-SNAPSHOT
```

线上可通过环境变量覆盖，例如：`APP_VERSION=1.0.0`（Spring 松散绑定 `app.version`）。

### 4.5 Docker 集成

`backend/Dockerfile` 中：

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://127.0.0.1:8080/health || exit 1
```

`wget --spider` 仅校验 HTTP 状态；**503** 会导致健康检查失败，容器可被编排系统重启。

---

## 5. 基础指标收集

### 5.1 实现说明

`RequestMetricsFilter`（`OncePerRequestFilter`）在请求结束后写入 **Micrometer**：

| 指标名 | 类型 | 含义 |
|--------|------|------|
| `beileme.http.requests` | Counter | HTTP 请求总数（不含 `/actuator/**`） |
| `beileme.http.request.duration` | Timer | 请求耗时（含 P50、P95 分位） |
| `beileme.http.errors` | Counter | HTTP 状态码 ≥ 400 的次数 |
| `beileme.active.users` | Gauge | 近 **15 分钟**内有过已认证请求的去重 `userId` 数量 |

**错误率（自行计算）：**

\[
\text{错误率} \approx \frac{\texttt{beileme.http.errors}}{\texttt{beileme.http.requests}}
\]

当请求数为 0 时无意义；建议在有一定流量后再观察。

活跃用户：JWT 校验通过后，`JwtInterceptor` 将 `userId` 写入 request 属性，Filter 在请求结束时调用 `ActiveUsersTracker.recordUser`。

### 5.2 Actuator 配置

`backend/src/main/resources/application.properties`：

```properties
management.endpoints.web.exposure.include=health,metrics
management.endpoint.health.show-details=never
```

当前**仅暴露** `health` 与 `metrics`，未开启 `prometheus` 等全部端点。

### 5.3 查询方式

本地默认端口 **8080**，先产生若干请求再查询：

```bash
# 列表
curl http://localhost:8080/actuator/metrics

# 请求总数
curl http://localhost:8080/actuator/metrics/beileme.http.requests

# 耗时（含 count、totalTime、max 等）
curl http://localhost:8080/actuator/metrics/beileme.http.request.duration

# 错误次数
curl http://localhost:8080/actuator/metrics/beileme.http.errors

# 活跃用户数
curl http://localhost:8080/actuator/metrics/beileme.active.users
```

**示例响应片段**（`beileme.http.requests`）：

```json
{
  "name": "beileme.http.requests",
  "description": "HTTP 请求总数",
  "measurements": [
    { "statistic": "COUNT", "value": 42.0 }
  ]
}
```

线上将 `localhost:8080` 换为后端公网地址（如 Railway 域名）；**注意访问控制**（见第 7 节）。

---

## 6. 本地验证步骤

### 6.1 启动后端

```bash
cd backend
./mvnw spring-boot:run
# 或 Windows: mvnw.cmd spring-boot:run
```

需本地 MySQL 已启动，且 `application.yml` 中数据源配置正确。

### 6.2 验证清单

| 步骤 | 命令 / 操作 | 预期 |
|------|-------------|------|
| 健康检查 | `curl http://localhost:8080/health` | `status: healthy`，`database: up` |
| 结构化日志 | 查看控制台或 `backend/logs/app.log` | 每行一条 JSON，含 `time`、`level`、`message`、`module` |
| 指标 | 访问几次 `/health` 后 `curl .../actuator/metrics/beileme.http.requests` | `value` > 0 |
| 错误指标 | 访问无 Token 的 `/api/words/daily` | `beileme.http.errors` 增加 |

### 6.3 课程截图建议

1. **Git 提交记录：** `git log --author="你的名字" --oneline --graph`
2. **健康检查：** 浏览器或终端展示 `/health` JSON
3. **结构化日志：** 控制台或 `logs/app.log` 中 JSON 行

---

## 7. 生产与 Railway 注意事项

| 项 | 建议 |
|----|------|
| `/health` | 可对负载均衡 / Railway 开放，用于探活 |
| `/actuator/metrics` | 仅内网或加网关鉴权；勿长期对公网完全开放 |
| 日志 | 使用平台日志采集（Railway Logs）；容器内 `logs/app.log` 重启后可能丢失，以 stdout 为主 |
| `app.version` | 发布时通过环境变量与镜像 tag 保持一致 |
| 告警（可选） | 可用外部服务对 `/health` 做 HTTP 探测；错误率阈值需对接 Prometheus/Grafana 或云平台告警（本仓库未内置） |

更完整的部署说明见 [deployment.md](./deployment.md)。

---

## 8. 相关源码索引

```
backend/
├── pom.xml                                          # logstash-logback-encoder、actuator
├── Dockerfile                                       # HEALTHCHECK → /health
├── src/main/resources/
│   ├── logback-spring.xml                           # JSON 日志
│   ├── application.yml                              # app.version、logging.level
│   └── application.properties                       # actuator 暴露端点
└── src/main/java/com/zychen/backend/
    ├── controller/HealthController.java
    ├── service/HealthService.java
    ├── service/impl/HealthServiceImpl.java
    ├── dto/response/HealthResponse.java
    └── config/
        ├── RequestMetricsFilter.java
        ├── ActiveUsersTracker.java
        └── MetricsConfig.java
```


# 监控配置贡献说明

姓名：陈子怡  
学号：2312190329  
日期：2026-05-27  

## 我完成的工作

### 1. 日志配置

- [x] 结构化日志格式（`backend/pom.xml` 增加 `logstash-logback-encoder`；`logback-spring.xml` 仅 `CONSOLE_JSON`，字段 `time`、`level`、`message`、`module`，另含 `app`；适配 Railway/Docker stdout 采集）
- [x] 日志级别配置（`application.yml` 中 `logging.level.root: INFO`、`com.zychen.backend: DEBUG`）

### 2. 健康检查

- [x] `/health` 端点实现（`HealthController` + `HealthResponse`；返回 `status`、`timestamp`、`version`、`database`；健康 200 / 不健康 503，与 `backend/Dockerfile` HEALTHCHECK 一致）
- [x] 健康检查逻辑（`HealthServiceImpl` 通过 `DataSource` 执行 `connection.isValid(2)` 探测 MySQL；版本来自 `app.version`）

### 3. 指标收集

- [x] 请求计数（Micrometer 指标 `beileme.http.requests`，`RequestMetricsFilter` 统计，排除 `/actuator/**`）
- [x] 响应时间（`beileme.http.request.duration` Timer，含 P50/P95）
- [x] 错误率（`beileme.http.errors` 统计 4xx/5xx；错误率 ≈ errors / requests，见 `docs/monitoring.md`）

补充：可选指标 `beileme.active.users`（近 15 分钟已认证去重用户）；Actuator 暴露 `health,metrics`（`application.properties`）；团队说明文档 `docs/monitoring.md`。

## PR 链接

- PR #89: https://github.com/xi1xi1/Words/pull/89

## 遇到的问题和解决

1. **问题：** 作业示例为 Python `JsonFormatter` / Node `winston`，本项目为 Spring Boot，不能直接照搬。  
   **解决：** 使用 Logback + `logstash-logback-encoder`，在 `logback-spring.xml` 中将 `logger` 字段映射为 `module`，满足课程 JSON 字段要求。

2. **问题：** 仓库原有 `/health` 仅返回 `{"status":"UP"}`，不满足作业要求的 `timestamp`、`version` 及探针逻辑。  
   **解决：** 新增 `HealthService` / `HealthResponse`，增加数据库连通性检查；不健康时返回 HTTP 503，便于 Docker / Railway 判定实例异常。

3. **问题：** 指标需在不大改业务代码的前提下统一采集。  
   **解决：** 使用 `OncePerRequestFilter` + Micrometer，经 Actuator `/actuator/metrics` 查询；单测 `RequestMetricsFilterTest`、`MetricsIntegrationTest` 验证指标递增。

## 心得体会

本次监控配置让我理解「可观测性」不只是打日志，而是把**日志、健康探针、指标**三条线打通：日志用于排障追溯， `/health` 供编排系统判断存活，指标用于发现请求量、延迟和错误趋势。Spring Boot 生态里 Actuator 与 Micrometer 能复用成熟方案，比从零造轮子更合适。生产环境需注意不要把 `/actuator` 无鉴权暴露到公网，敏感信息仍应只走环境变量。编写 `docs/monitoring.md` 也帮助团队统一本地验证与截图方式，便于学习通提交。

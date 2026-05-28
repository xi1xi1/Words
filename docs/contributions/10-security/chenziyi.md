# 安全审查贡献说明

姓名：陈子怡  
学号：2312190329  
日期：2026-05-06

## 我完成的工作

### AI 安全审查

- **审查了哪些文件/模块：**
  - 认证与鉴权：`AuthServiceImpl`、`JwtUtil`、`JwtInterceptor`、`WebConfig`、`AuthController`
  - 业务接口：`UserController`、`StudyController`、`LeaderboardController`、`ChallengeController`、`WordController`、`WordbookController`
  - 数据访问：`backend/src/main/java/**/mapper`、`backend/src/main/resources/mapper/**/*.xml`
  - 全局异常与 AI：`GlobalExceptionHandler`、`AIServiceImpl`（含 `ark.*` 等 `@Value` 配置）
  - 工程与 DevOps：`backend/pom.xml`、`docker-compose.yml`、`.github/workflows/ci.yml`、`.gitignore`

- **AI 发现的主要问题：**
  1. JWT 密钥需外部化并满足长度要求；登出黑名单须在拦截器与 `validateToken` 链路中一致生效。
  2. 各 Controller 上 `CrossOrigin(origins = "*")` 过宽，需改为可配置 CORS 白名单。
  3. Actuator 暴露面需在配置中显式收紧；注册密码强度不足。
  4. Mapper 层需确认无 `${}` 动态拼接导致的 SQL 注入面。
  5. 大模型调用路径存在提示注入风险，需在入模前对用户可控文本做净化。
  6. CI 上 `SpringBootTest` 曾出现上下文加载失败，与测试环境数据源/MyBatis 配置未稳定注入有关。

- **我修复了哪些问题：**
  1. `JwtUtil`：`jwt.secret` 必填与 UTF-8 下最小长度校验；`JwtInterceptor` 改为通过 `AuthService.validateToken` 校验（含登出黑名单）。
  2. `WebConfig` + 主配置：`app.cors.allowed-origins` 白名单；移除各 Controller 上过宽的 `@CrossOrigin`。
  3. `RegisterRequest`：密码长度与复杂度（字母+数字等）校验。
  4. `management.endpoints.web.exposure.include=health`，`health.show-details=never`。
  5. 新增 `PromptInputSanitizer`，在 `AIServiceImpl` 构建 prompt 时使用；补充 `PromptInputSanitizerTest`。
  6. 文档与模板：维护合并版安全记录 `docs/security-review.md`；新增根目录 `.env.example`；`.github/dependabot.yml` 增加 **maven**（`/backend`）。
  7. CI 与测试可重复性：`ci.yml` 中为 `mybatis.mapper-locations` 的 `-D` 参数加引号；`backend/src/test/resources/application.properties` 补齐与 CI MySQL 一致的 `spring.datasource.*` 与 `mybatis.*`；`.gitignore` 增加对测试用 `application.properties` 的例外（`!backend/src/test/resources/application.properties`）。

### 安全检查清单

（以下为第二步合并清单的勾选情况；**不适用**项已在说明中标注。）

#### 认证与授权

- [x] 密码存储：后端 BCrypt；`UserMapper` 使用 `#{password}`；前端不存密码。
- [x] JWT / Session：过期时间、登出黑名单、`JwtInterceptor` 经 `AuthService.validateToken`。
- [x] 接口鉴权：`/api/**` 走拦截器，仅放行注册与登录。
- [x] 越权访问（主体）：`userId` 来自 JWT / 拦截器写入属性；前端不以页面参数当权限。


#### 注入防护

- [x] SQL：MyBatis 使用 `#{}`，已检索无 `${}` 拼接风险（**适用**）。
- [x] XSS（后端视角）：JSON API、通用异常不返回堆栈（**适用**）；反射型 XSS 主要在前端展示层，后端为部分适用，已在总文档说明。

#### 敏感信息

- [x] JWT / 数据库 / AI Key：无源码默认 JWT 密钥；Compose 与配置注入；勿提交含真实密钥的 `application.yml`。
- [x] `.env`：`.gitignore` 忽略 `.env`；仓库提供 `.env.example`；真实值经本地 `.env` 或环境变量 / 部署 Secret 注入。
- [ ] CI 口令：`ci.yml` 中测试库口令仍为明文（**适用，待改进**），建议改为 Secrets。

#### 依赖安全

- [x] Dependabot：Pub、GitHub Actions、Maven（`/backend`）。
- [x] Gitleaks：`.github/workflows/security.yml`。
- [x] Maven `dependency:analyze`：已执行且 `BUILD SUCCESS`。
- [ ] CVE / 依赖漏洞自动化扫描：**不适用「已完成」**——`dependency:analyze` 非 CVE 扫描；待接入 Dependency-Check 或 SCA 后勾选。

### CI 安全扫描

- **配置了哪个选项（A/B/C）：** **A**（密钥泄露扫描）。
- **扫描结果：** 以 GitHub Actions 中 **Gitleaks** 工作流最近一次运行结果为准；通过表示未报告密钥模式命中（若有告警需轮换密钥并清理泄露）。

### 选做完成情况

- **Prompt 注入防护**（AI 输入净化）：在 `AIServiceImpl` 调用 Ark 前通过 `PromptInputSanitizer` 处理用户侧 `word` / `meaning` 等；`PromptInputSanitizerTest` 覆盖基础用例。

## PR 链接

- PR #68: https://github.com/xi1xi1/Words/pull/68（合并后替换为实际链接）

## 遇到的问题和解决

1. **问题：** CI 上大量 `SpringBootTest` 报 `Failed to load ApplicationContext`。  
   **解决：** 在测试 `application.properties` 中固定与 CI 一致的 JDBC 与 MyBatis 配置；修正 `ci.yml` 里 `mybatis.mapper-locations` 的 shell 引号；为测试配置文件增加 `.gitignore` 例外以便入库。

2. **问题：** Actions 日志中 Spring 自动配置输出过多，难以定位根因。  
   **解决：** 在测试配置中降低 `org.springframework.boot.autoconfigure` 等日志级别；在完整 log 中从后往前搜索 `Caused by` / `Rule violated`。

## 心得体会

在 Vibe Coding 下，功能可以很快堆起来，但安全要靠**可重复的验证**：密钥是否外置、登出是否真正失效、CORS 是否过宽、CI 是否稳定绿、是否有密钥扫描与依赖更新渠道。AI 适合做大范围初筛和文档整理，**不能替代**对关键路径（鉴权、SQL、配置、流水线）的人工核对；效率与安全之间，宁可多一步门禁和一条稳定的测试配置，少一次演示或提交作业时的翻车。

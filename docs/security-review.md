# 安全审查与加固记录

## 一、审查目标

本次安全审查基于 **OWASP Top 10** 思路，对「背了么」项目进行安全风险排查，并完成**前端**与**后端**相关安全加固及自动化安全扫描配置说明。

- **前端**：网络与认证相关模块的日志脱敏、输入校验、错误信息脱敏、防重复提交等（成员：张欣）。
- **后端**：认证与授权、注入防护、敏感信息与依赖安全；与 CI、Docker 相关的配置风险；与《安全检查清单（第二步）》对齐。

**文档涉及路径（节选）：**  
`frontend/lib/...`（见第二节）、`backend/src/main/java/`、`backend/src/main/resources/`、`backend/pom.xml`、`docker-compose.yml`、`.github/workflows/`、`.gitignore`。

---

## 二、前端安全审查

### 2.1 审查范围

前端主要审查以下前端模块：

- `frontend/lib/core/network/api_client.dart`
- `frontend/lib/core/network/interceptors/auth_interceptor.dart`
- `frontend/lib/services/auth_service.dart`
- `frontend/lib/core/providers/user_provider.dart`
- `frontend/lib/core/constants/api_constants.dart`
- `frontend/lib/features/auth/screens/login_screen.dart`
- `frontend/lib/features/auth/screens/register_screen.dart`

### 2.2 AI 辅助审查发现

| 序号 | 问题 | 风险等级 | 影响 | 处理结果 |
|---|---|---|---|---|
| 1 | 前端调试日志直接输出请求头，可能包含 `Authorization: Bearer <token>` | 中 | Token 可能在控制台、截图或日志中泄露 | 已修复：请求头日志脱敏，仅显示 `Bearer ***` |
| 2 | 登录/注册输入校验偏基础，未统一处理 trim、用户名字符范围和密码空白校验 | 中 | 可能提交空白输入、弱密码或异常字符，增加账号安全风险 | 已修复：增强用户名、邮箱、密码和确认密码校验 |
| 3 | 前端使用 `SharedPreferences` 保存 token | 低 | 移动端本地存储存在被调试环境读取的可能 | 当前项目保留该实现；已确认登出和 401 场景会清理 token，后续可升级到安全存储 |
| 4 | Flutter 前端未使用 HTML/DOM 直接渲染用户输入 | 低 | XSS 风险较低 | 记录为不适用；若后续引入 WebView/HTML 渲染需补充过滤 |
| 5 | 前端直接展示后端原始错误信息 | 中 | 可能暴露 SQL、JWT、异常栈等内部细节 | 已修复：新增统一安全错误提示 `safeMessage` |
| 6 | 响应体日志直接输出接口返回内容 | 中 | 登录响应中的 token 等敏感字段可能进入日志 | 已修复：响应体日志递归脱敏并仅在 debug 模式输出 |
| 7 | 极端情况下登录/注册可能重复提交 | 低 | 可能造成重复请求或接口压力 | 已修复：提交处理开头增加 `_isLoading` 防重入 |

### 2.3 已完成的前端修复

#### 修复 1：请求日志敏感信息脱敏

位置：`frontend/lib/core/network/api_client.dart`

处理方式：

- 新增请求头脱敏方法，对 `Authorization` 统一输出为 `Bearer ***`
- 新增请求体脱敏方法，对 `password`、`token`、`authorization` 等敏感字段输出为 `***`
- 保留必要调试信息，但避免泄露 token 和密码

#### 修复 2：登录/注册输入校验增强

位置：

- `frontend/lib/features/auth/screens/login_screen.dart`
- `frontend/lib/features/auth/screens/register_screen.dart`

处理方式：

- 用户名统一 `trim()` 后校验
- 限制用户名长度和字符范围
- 注册邮箱使用更通用的邮箱格式校验
- 注册密码限制长度并禁止全部空格
- 确认密码复用密码格式校验并检查一致性

#### 修复 3：前端错误信息统一脱敏

位置：

- `frontend/lib/core/network/api_exception.dart`
- `frontend/lib/features/auth/screens/login_screen.dart`
- `frontend/lib/features/auth/screens/register_screen.dart`

处理方式：

- 新增 `safeMessage`，按错误码转换为用户友好提示
- 登录/注册页不再直接展示后端原始 `message`
- 避免 SQL、JWT、异常栈等内部错误细节暴露给用户

#### 修复 4：响应日志脱敏并限制在 debug 模式输出

位置：`frontend/lib/core/network/api_client.dart`

处理方式：

- 新增 `_debugLog`，仅在 `kDebugMode` 下输出网络日志
- 新增响应体递归脱敏逻辑，对 `token`、`password`、`authorization` 等字段输出 `***`
- 保留调试能力，同时降低 release 构建与日志中的敏感信息泄露风险

#### 修复 5：登录/注册防重复提交

位置：

- `frontend/lib/features/auth/screens/login_screen.dart`
- `frontend/lib/features/auth/screens/register_screen.dart`

处理方式：

- 在 `_handleLogin` 和 `_handleRegister` 开头增加 `_isLoading` 防重入判断
- 防止极端情况下连续点击导致重复请求

---

## 三、后端安全审查

### 3.1 审查范围

后端审查主要覆盖以下模块与文件（按职责归类）：

| 类别 | 路径或文件 |
|------|------------|
| 认证与鉴权 | `AuthServiceImpl.java`、`JwtUtil.java`、`JwtInterceptor.java`、`WebConfig.java`、`AuthController.java` |
| 用户与业务接口 | `UserController.java`、`StudyController.java`、`LeaderboardController.java`、`ChallengeController.java`、`WordController.java`、`WordbookController.java` |
| 数据访问与实体 | `**/mapper/*.java`、`src/main/resources/mapper/*.xml`、`User.java`、`UserMapper.java` |
| 全局异常与 AI 调用 | `GlobalExceptionHandler.java`、`AIServiceImpl.java` |
| 构建与运行配置 | `backend/pom.xml`、`application.properties`、`docker-compose.yml`、`.github/workflows/ci.yml`、`.gitignore` |

### 3.2 审查发现（摘要表）

| 序号 | 问题 | 风险等级 | 影响 | 处理结果 |
|------|------|----------|------|----------|
| 1 | JWT 密钥缺失或弱配置、源码内默认密钥 | 高 | 攻击者可伪造 Token，绕过认证 | **已修复**：`JwtUtil` 使用 `@Value("${jwt.secret}")` 无默认密钥，`@PostConstruct` 校验非空及 UTF-8 编码后不少于 32 字节 |
| 2 | 登出后 Token 在拦截器未校验黑名单，仍可调受保护接口 | 高 | 会话无法真正撤销 | **已修复**：`JwtInterceptor` 调用 `AuthService.validateToken`，与 `logout` 写入的黑名单一致 |
| 3 | Controller 层 `CrossOrigin(origins = "*")` 过宽 | 中 | 浏览器任意 Origin 跨域调用 API | **已修复**：`WebConfig` 配置 `app.cors.allowed-origins` 白名单，移除各 Controller 上 `origins = "*"` |
| 4 | Actuator 端点暴露面未在配置中显式收紧 | 中 | 误配时可能暴露环境、指标等 | **已修复**：`application.properties` 中 `management.endpoints.web.exposure.include=health`，`show-details=never` |
| 5 | 注册密码强度不足 | 中 | 弱密码、暴力破解 | **已修复**：`RegisterRequest` 增加 `@Size(min=8,max=72)` 与 `@Pattern`（须含字母与数字） |
| 6 | CI 流水线中硬编码数据库口令 | 中 | 流水线日志或仓库可见性导致口令泄露习惯外溢 | **待改进**：`.github/workflows/ci.yml` 中 `123456` 等应改为 GitHub `secrets` 注入 |
| 7 | Token 黑名单仅存进程内 `ConcurrentHashMap` | 中 | 多实例部署时登出仅对单节点生效 | **待改进**：Redis 等共享黑名单或缩短 Access Token 周期 + Refresh 方案 |
| 8 | 生词本 AI 接口未校验 `wordId` 是否属于当前用户生词本 | 低 | 已登录用户可滥用外部 AI 配额与成本 | **待改进**：业务层增加 `isInWordbook` 等归属校验 |
| 9 | SQL 注入检查：是否存在 `${}` 动态拼接或字符串拼接 SQL | 高（若存在） | 若存在动态拼接，可能导致数据库泄露或篡改 | **已满足**：已检索 Mapper 注解与 XML，未发现 `${}` 动态拼接，LIKE 使用 `#{}` 与 `CONCAT` 参数绑定 |

### 3.3 已完成的后端修复（与代码位置对照）

#### 修复 1：JWT 密钥强制外部化与启动期校验

**位置：** `backend/src/main/java/com/zychen/backend/config/JwtUtil.java`

**处理方式：**

- 使用 `@Value("${jwt.secret}")`，移除源码内默认密钥字符串。
- `@PostConstruct` 校验密钥非空及 UTF-8 编码长度满足 HS256 要求。
- `getSigningKey()` 使用 `StandardCharsets.UTF_8` 编码，避免平台默认编码差异。

**测试配套：** `backend/src/test/resources/application.properties` 中提供满足校验的测试用 `jwt.secret`（仅用于测试）。

#### 修复 2：登出黑名单与拦截器校验路径统一

**位置：** `backend/src/main/java/com/zychen/backend/config/JwtInterceptor.java`、`AuthServiceImpl.java`

**处理方式：**

- `AuthServiceImpl` 在 `logout` 时将 Token 写入内存黑名单，`validateToken` 先查黑名单再调用 `JwtUtil.validateToken`。
- `JwtInterceptor` 将原 `jwtUtil.validateToken` 改为 `authService.validateToken`，确保登出后的 Token 无法继续访问 `/api/**` 受保护接口。

#### 修复 3：CORS 白名单与全局注册

**位置：** `backend/src/main/java/com/zychen/backend/config/WebConfig.java`、`backend/src/main/resources/application.properties`

**处理方式：**

- 删除各 Controller 上 `@CrossOrigin(origins = "*")`。
- 在 `WebConfig#addCorsMappings` 中对 `/api/**` 使用 `app.cors.allowed-origins` 解析后的 Origin 数组；启动时校验列表非空。

#### 修复 4：Actuator 最小暴露

**位置：** `backend/src/main/resources/application.properties`（测试环境同项见 `src/test/resources/application.properties`）

**处理方式：**

- `management.endpoints.web.exposure.include=health`
- `management.endpoint.health.show-details=never`

#### 修复 5：注册密码复杂度

**位置：** `backend/src/main/java/com/zychen/backend/dto/request/RegisterRequest.java`

**处理方式：**

- 密码长度 8–72 位，正则要求同时包含字母与数字；与 BCrypt 常见长度上限对齐。

### 3.4 详细审查记录（完整对照表）

以下表格为第二步清单的**完整逐项记录**（与历史版本一致，未删减字段），可与 3.2 摘要表对照使用。

| 序号 | 检查项 | 是否适用 | 当前检查结果（基于实际代码） | 已处理方式 | 未处理原因与改进方案 |
|------|--------|----------|------------------------------|------------|----------------------|
| 1 | 密码存储（BCrypt/Argon2，无明文落库） | 适用 | `AuthServiceImpl` 注册时使用 `BCryptPasswordEncoder.encode`；登录使用 `matches`；`UserServiceImpl` 修改密码同样使用 BCrypt。`UserMapper.insert` / `updatePassword` 使用 `#{password}` 绑定，不在 SQL 中写死明文。`User` 实体含 `password` 字段为持久化所需，属常见做法。 | 业务层统一使用 BCrypt；数据库侧仅存哈希（具体哈希值需结合运行库确认，属运维范畴）。 | **需人工确认：** 历史或种子数据中是否存在明文密码账号。改进：迁移脚本校验、首次登录强制改密（属产品策略，未在本次范围实现）。 |
| 2 | JWT：过期时间、登出后失效 | 适用 | `JwtUtil` 中 `expiration` 默认 `86400000` ms（约 24h），生成 Token 时设置 `setExpiration`。`AuthServiceImpl.logout` 将 Token 字符串写入 `ConcurrentHashMap` 黑名单；`validateToken` 先查黑名单再调用 `jwtUtil.validateToken`。`JwtInterceptor` 使用 `authService.validateToken(token)`，与登出逻辑一致。 | 已实现过期校验 + 进程内黑名单 + 拦截器统一校验。 | 黑名单**非分布式**：多实例部署时实例间不同步，登出仅对当前节点生效。改进：Redis 等共享黑名单或缩短 Token 有效期 + Refresh Token 方案。**需人工确认：** 负载拓扑是否为单实例。 |
| 3 | 接口鉴权（需登录接口经拦截器） | 适用 | `WebConfig` 对 `/api/**` 注册 `JwtInterceptor`，仅排除 `/api/auth/register`、`/api/auth/login`。`OPTIONS` 在拦截器内直接放行。各 `Controller` 的 `@RequestMapping` 均为 `/api/...`。公开接口为注册与登录；`POST /api/auth/logout` 未排除，需携带有效 Bearer Token（与注释一致）。 | 路径级保护与会话外放行策略已配置。 | **需人工确认：** 是否存在未纳入本仓库的额外 `DispatcherServlet` 映射或 Actuator 非标准路径暴露（当前 `application.properties` 仅暴露 `health`）。`JwtUtil.getUserIdFromRequest` 在缺少 `userId` 属性时回退为自行解析 JWT 且调用 `jwtUtil.validateToken`（**未走黑名单**）；正常链路下拦截器已写入 `userId`，该回退路径风险较低，仍建议统一委托 `AuthService.validateToken`。 |
| 4 | 越权访问（userId 来源与数据绑定） | 适用 | 已查阅各 `Controller`：`userId` 多来自 `@RequestAttribute("userId")`（由拦截器从 JWT 写入），未发现由客户端直接传入 `userId` 作为身份凭据的路径变量。`StudyController` 使用 `jwtUtil.getUserIdFromRequest(request)`，在拦截器已执行时与 Token 一致。业务层如 `WordServiceImpl.submitLearnResult`、`UserWordMapper` 等均使用传入的 `userId` 与 `wordId` 联合条件。 | 身份标识主要来自服务端解析的 JWT，符合常规设计。 | `WordbookServiceImpl.getAIContent(Long userId, Long wordId)` 中 **`userId` 未用于校验该 `wordId` 是否属于当前用户生词本**，任意已登录用户可触发对任意 `wordId` 的 AI 调用（资源滥用/成本风险）。改进：调用前校验 `userWordMapper.isInWordbook` 或等价业务规则。闯关提交等业务逻辑完整性（如服务端判题）属**业务防作弊**，未列入本表 SQL/鉴权项，**需人工确认**是否单独纳入需求。 |
| 5 | SQL 注入 | 适用 | 已检索 `backend/src/main/java/**/mapper/**/*.java` 与 `backend/src/main/resources/mapper/**/*.xml`：**未发现 `${}`**。注解 SQL 与 XML 均使用 `#{}` 绑定。`WordMapper` 中 `LIKE` 使用 `CONCAT('%', #{keyword}, '%')`，关键字为预编译参数。 | 当前可见代码符合 MyBatis 安全参数绑定习惯。 | 后续新增 Mapper 须 Code Review 禁止 `${}` 拼接动态表名/列名；复杂动态 SQL 优先 `<script>` + `#{}`。 |
| 6 | XSS（后端 API 视角） | 部分适用 | 控制器返回 `ApiResponse` + JSON，**未发现**服务端模板渲染 HTML 页面。异常处理 `GlobalExceptionHandler` 对通用异常返回固定文案「服务器内部错误」，不向客户端输出堆栈。 | 反射型 XSS 主要风险在前端如何将 JSON 插入 DOM；后端职责为 JSON API 与避免在错误响应中拼接未转义 HTML。 | 若前端将 `avatar`、AI 返回文案等直接 `innerHTML` 插入，仍可能 XSS，**由前端负责转义/使用文本节点**。后端可对存储型内容做长度与格式校验（属增强项）。 |
| 7 | API Key / 密码硬编码 | 适用 | `JwtUtil`：`@Value("${jwt.secret}")`，**无**源码内默认密钥；`@PostConstruct` 校验非空与最小长度。`AIServiceImpl`：`ark.api-key`、`ark.endpoint-id` 默认为空字符串，由配置注入；`ark.base-url` 存在公开默认 URL（非密钥）。`docker-compose.yml`：数据库与 `JWT_SECRET` 使用 `${...}` 从环境读取，带必填提示。`.github/workflows/ci.yml`：MySQL 与 JDBC 使用**明文 `123456`**。仓库内 `backend/src/main/resources/application.properties` 含 **CORS 白名单与 Actuator 配置，无数据库口令、无 JWT 密钥**。 | 生产导向配置依赖 `.env`/环境变量；JWT 强制外部配置。 | **待改进（低）：** CI 中硬编码口令应改为 GitHub `secrets` 或等价机制。**需人工确认：** `.gitignore` 中 `**/application.properties` 与仓库是否跟踪该文件并存——团队应统一「默认配置是否入库」与敏感项是否仅环境注入。 |
| 8 | .env 与 .gitignore | 适用 | `.gitignore` 包含 `**.env`、`**.env.*.local` 等；仓库根目录提供 **`.env.example`**（仅变量名与占位值）；`docker-compose.yml` 注释要求复制为 `.env` 并填写敏感项。Spring 可通过环境变量覆盖 `JWT_SECRET`、`SPRING_DATASOURCE_*`、`APP_CORS_ALLOWED_ORIGINS`、`ARK_*` 等（与 `JwtUtil`、`WebConfig`、`AIServiceImpl` 及 Compose 注入一致）。 | 敏感值不入库；示例文件 + Compose 引导本地与容器注入。 | **需人工确认：** 含机密的 `application.yml` / `application.properties` 是否仅保留本地（`.gitignore` 亦忽略 `**/application.yml` 等，与团队约定一致）。 |
| 9 | 依赖扫描 / `dependency:analyze` | 适用 | 已在 `backend` 目录执行 Maven Wrapper（见第五节）。 | 完成 Maven 依赖静态分析。 | `dependency:analyze` **不是** CVE 漏洞扫描。改进：接入 **OWASP Dependency-Check**、**GitHub Dependabot** 或厂商 SCA，并与 `mvn versions:display-dependency-updates` 结合做版本治理。 |

---

## 四、安全检查清单

### 认证与授权

- [x] 密码存储：前端不存储密码；后端注册与改密使用 BCrypt，`UserMapper` 使用 `#{password}` 参数绑定。
- [x] JWT / Session：前端保存 JWT，并在 logout、401 场景清理本地 token；后端 JWT 含过期时间，登出写入黑名单，`JwtInterceptor` 经 `AuthService.validateToken` 校验（含黑名单）。
- [x] 接口鉴权：前端经 `ApiClient` 为需登录接口添加 `Authorization`；后端 `/api/**` 默认走 `JwtInterceptor`，仅放行 `/api/auth/register`、`/api/auth/login`。
- [x] 越权访问（主体）：后端以 JWT / `@RequestAttribute("userId")` 等为主，业务 SQL 多绑定 `user_id`；前端不将页面参数视为权限依据。

### 注入防护

- [x] SQL：前端不直接操作数据库；后端 MyBatis 使用 `#{}` 绑定，无 `${}`，LIKE 使用参数绑定。
- [x] XSS：前端 Flutter 未用 `innerHTML`、当前无 WebView/HTML 直渲染；后端仅返回 JSON，无服务端 HTML 模板，通用异常不返回堆栈给客户端。

### 敏感信息

- [x] API Key / 密码 / JWT Secret：前端未硬编码密钥，请求与响应日志已对 token、密码等脱敏；后端无源码内默认 `jwt.secret`，须配置 `jwt.secret` 或 `JWT_SECRET`；数据库与 AI 相关密钥由 `docker-compose` 环境占位、`AIServiceImpl` 配置注入（勿将含真实密钥的 `application.yml` 等提交至公开仓库）。
- [x] `.env` / 密钥注入：`.gitignore` 已忽略 `.env`（及多种 `.env.*` 变体），勿将含真实密码、API Key、JWT Secret 的 `.env` 提交入库；仓库根目录仅提供 **`.env.example`**（变量名与占位说明）。真实密钥与口令应通过**本地 `.env`、操作系统环境变量或部署平台 Secret** 注入；`docker-compose.yml` 从 `.env` 读取 `MYSQL_ROOT_PASSWORD`、`JWT_SECRET` 等；Spring 可通过 `JWT_SECRET`、`SPRING_DATASOURCE_*`、`APP_CORS_ALLOWED_ORIGINS`、`ARK_*` 等覆盖 `jwt.*`、`spring.datasource.*`、`app.cors.*`、`ark.*`（与 `JwtUtil`、`WebConfig`、`AIServiceImpl` 一致）。前端当前未使用 `.env`，若后续接入第三方密钥可沿用同一约定并补充前端示例段。

### 依赖安全

- [x] Dependabot：已监控 Flutter Pub、GitHub Actions 与后端 Maven（`package-ecosystem` 分别为 `pub`、`github-actions`、`maven`，见 `.github/dependabot.yml`）。
- [x] Gitleaks：已配置全仓密钥泄露扫描（`.github/workflows/security.yml`）。
- [x] Maven 依赖分析：已执行 `mvnw.cmd dependency:analyze`，`BUILD SUCCESS`（详见第五节）。


---

## 五、CI 与依赖自动化安全相关

### 5.1 密钥泄露扫描（Gitleaks）

本次作业选项 A：**密钥泄露扫描**。

- **Workflow：** `.github/workflows/security.yml`
- **工具：** `gitleaks/gitleaks-action@v2`
- **触发：** `push` / `pull_request` 至 `master`、`develop` 分支（以仓库内 workflow 实际配置为准）。

### 5.2 Maven 依赖分析（`dependency:analyze`）

**说明：** 本项为**依赖声明与传递关系分析**，**不是** CVE 漏洞扫描。

**实际执行命令：**

```text
cd backend
.\mvnw.cmd dependency:analyze
```

（Linux/macOS 可使用 `./mvnw dependency:analyze`；须 JDK 17 与项目自带 Maven Wrapper。）

**结果摘要：**

- **退出码：** 成功（`BUILD SUCCESS`）。
- **插件：** `dependency:3.8.1:analyze`（以 Maven 解析为准）。
- **报告要点：**
  - **Used undeclared dependencies found：** 多为 Spring Boot / MyBatis 传递依赖，属常见现象，**不代表**存在安全漏洞。
  - **Unused declared dependencies found：** 对 Starter 聚合依赖易出现**误报**，删除前须结合 `dependency:tree` **人工确认**。
- **后续建议：** 接入 **OWASP Dependency-Check** 或企业 SCA，与 **Dependabot**（已含 Pub、Actions、Maven）及版本升级流程结合。

### 5.3 CI 流水线与敏感配置说明

- **数据库口令：** `.github/workflows/ci.yml` 中仍为便于 CI 环境的明文口令（如 `123456`），与「不在仓库硬编码敏感信息」的最佳实践不符；**建议**改为 GitHub Actions `secrets` 注入或 CI 专用随机口令。
- **Gitleaks：** 与 5.1 一致，对全仓文本与历史做密钥模式扫描。

---

## 六、结论

**前端：** 本次前端安全审查未发现高危漏洞。已完成多处有意义的前端安全加固：请求/响应日志敏感信息脱敏、登录/注册输入校验增强、错误信息统一脱敏、网络日志仅 debug 模式输出、登录/注册防重复提交。同时仓库已配置 **Gitleaks** 与 **Dependabot**，满足课程对自动化安全扫描与依赖监控的基本要求。

**后端：** 本次后端安全审查**未发现高危 SQL 注入面**（当前 Mapper 未见 `${}`），在**认证与授权**方向已完成多项实质性加固：**JWT 密钥强制配置**、**登出黑名单与拦截器统一校验**、**CORS 白名单**、**Actuator 最小暴露**、**注册密码复杂度校验**。仍须关注：**CI 硬编码口令**、**依赖 CVE 自动化扫描缺位**、**令牌黑名单多实例一致性**及**个别业务接口的资源归属校验**；其中 SCA 建议作为下一迭代高优先级项。部署与版本管理方面，**`.gitignore` 与是否跟踪含密钥的 `application.yml` / `application.properties`** 建议团队书面约定，避免敏感配置漂移。

---

**文档维护：** 与仓库前后端代码及 CI 配置同步整理；代码或流水线变更后请重新执行 `dependency:analyze`、核对 Gitleaks 与 Dependabot 状态，并抽样更新本文档。

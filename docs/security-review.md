# 安全审查与加固记录

## 一、审查目标

本次安全审查基于 OWASP Top 10 思路，对“背了么”项目进行安全风险排查，并完成前端相关安全加固与自动化安全扫描配置。

## 二、前端安全审查

### 2.1 审查范围

前端成员张欣主要审查以下前端模块：

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

## 三、安全检查清单

### 认证与授权

- [x] 密码存储：前端不存储密码；密码哈希由后端负责。
- [x] JWT / Session：前端保存 JWT，并在 logout 和 401 场景清理本地 token。
- [x] 接口鉴权：前端统一通过 `ApiClient` 为需登录接口添加 `Authorization` 请求头。
- [x] 越权访问：主要由后端校验；前端不将页面参数视为权限依据。

### 注入防护

- [x] SQL：前端不直接操作 SQL，数据库访问由后端负责。
- [x] XSS：Flutter 页面未使用 `innerHTML`，当前不涉及 WebView/HTML 注入渲染。

### 敏感信息

- [x] API Key / 密码：前端未硬编码 API Key 或密码；请求和响应日志已对 token/密码脱敏。
- [x] `.env` 文件：当前前端未使用 `.env`；如后续接入第三方密钥，需要补充 `.env.example` 并忽略真实 `.env`。

### 依赖安全

- [x] 已通过 Dependabot 监控 Flutter Pub 与 GitHub Actions 依赖更新。
- [x] 已新增 Gitleaks 自动扫描，检查仓库中潜在密钥泄露。

## 四、CI 自动化安全扫描

本次选择选项 A：密钥泄露扫描。

新增 workflow：

- `.github/workflows/security.yml`

扫描工具：

- `gitleaks/gitleaks-action@v2`

触发方式：

- push 到 `master` / `develop`
- pull request 到 `master` / `develop`

## 五、结论

本次前端安全审查未发现高危漏洞。已完成多处有意义的前端安全加固：请求/响应日志敏感信息脱敏、登录/注册输入校验增强、错误信息统一脱敏、网络日志仅 debug 模式输出、登录/注册防重复提交。同时已新增 Gitleaks 自动化密钥泄露扫描，满足本周安全审查与加固作业要求。

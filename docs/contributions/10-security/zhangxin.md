# 安全审查贡献说明

姓名：张欣  
学号：2312190333  
日期：2026-05-06

## 我完成的工作

### AI 安全审查

- 审查了哪些文件/模块：
  - `frontend/lib/core/network/api_client.dart`
  - `frontend/lib/core/network/interceptors/auth_interceptor.dart`
  - `frontend/lib/services/auth_service.dart`
  - `frontend/lib/core/providers/user_provider.dart`
  - `frontend/lib/core/constants/api_constants.dart`
  - `frontend/lib/features/auth/screens/login_screen.dart`
  - `frontend/lib/features/auth/screens/register_screen.dart`

- AI 发现的主要问题：
  1. 前端请求日志会输出完整请求头，存在 `Authorization` token 泄露风险。
  2. 登录/注册输入校验偏基础，未统一处理空白输入、用户名字符范围和密码空白校验。
  3. 前端使用本地偏好存储保存 token，需确保 logout 和 401 场景及时清理。

  4. 前端直接展示后端原始错误信息，可能暴露内部异常细节。
  5. 响应体日志直接输出接口返回内容，登录响应中的 token 可能进入日志。
  6. 登录/注册极端情况下可能重复提交请求。

- 我修复了哪些问题：
  1. 在 `ApiClient` 中对请求头和请求体日志进行脱敏，避免输出 token、密码等敏感信息。
  2. 增强登录/注册页面输入校验，增加用户名字符范围、长度、邮箱格式、密码长度和确认密码校验。
  3. 新增 `ApiException.safeMessage`，登录/注册页统一展示脱敏后的用户友好错误提示。
  4. 将网络请求/响应日志限制在 debug 模式输出，并对响应体中的敏感字段递归脱敏。
  5. 在登录/注册提交入口增加 `_isLoading` 防重入判断，避免重复提交。

### 安全检查清单

#### 认证与授权

- [x] 密码存储：前端不存储密码；密码哈希由后端负责。
- [x] JWT / Session：前端保存 JWT，并在 logout 和 401 场景清理本地 token。
- [x] 接口鉴权：前端统一通过 `ApiClient` 为需登录接口添加 `Authorization` 请求头。
- [x] 越权访问：主要由后端校验；前端不将页面参数视为权限依据。

#### 注入防护

- [x] SQL：前端不直接操作 SQL，数据库访问由后端负责。
- [x] XSS：Flutter 页面未使用 `innerHTML`，当前不涉及 WebView/HTML 注入渲染。

#### 敏感信息

- [x] API Key / 密码：前端未硬编码 API Key 或密码；请求和响应日志已对 token/密码脱敏。
- [x] `.env` 文件：当前前端未使用 `.env`；如后续接入第三方密钥，需要补充 `.env.example` 并忽略真实 `.env`。

#### 依赖安全

- [x] 已通过 Dependabot 监控 Flutter Pub 与 GitHub Actions 依赖更新。
- [x] 已新增 Gitleaks 自动扫描，检查仓库中潜在密钥泄露。

### CI 安全扫描

- 配置了哪个选项：选项 A，密钥泄露扫描。
- 新增文件：`.github/workflows/security.yml`
- 扫描工具：`gitleaks/gitleaks-action@v2`
- 扫描结果：等待 GitHub Actions 运行后截图记录，预期 `Gitleaks Secret Scan` 通过。

### 选做完成情况

- [x] 结合上一周 CI/CD 配置，仓库已启用 Dependabot 依赖更新监控。
- [x] 已集成 CodeRabbit AI 代码审查，可用于 PR 安全审查辅助。

## PR 链接

- PR #X: https://github.com/xi1xi1/Words/pull/X

## 遇到的问题和解决

1. 问题：前端调试日志需要保留排查能力，但不能输出 token 和密码。  
   解决：新增日志脱敏逻辑，仅隐藏敏感字段，保留请求方法、URL、状态码等非敏感信息。

2. 问题：Flutter 前端不适用 PDF 中的 `innerHTML`、SQL 等部分检查项。  
   解决：在安全检查清单中明确说明前端适用范围，对不适用项标注由后端负责或当前不涉及。

## 心得体会

Vibe Coding 可以提升开发效率，但安全审查不能只依赖功能是否可运行。前端虽然不直接接触数据库和密码哈希，但仍然需要关注 token 日志泄露、输入校验、错误提示和依赖安全。通过 AI 辅助审查，可以更快定位风险点；最终仍需要结合项目实际代码进行判断和验证。

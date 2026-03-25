# API 设计与实现贡献说明

**姓名**：[张欣]  
**学号**：[2312190333]  
**日期**：2026-03-25

## 我完成的工作

### 1. API 设计

- [x] 用户认证 API（注册、登录、登出）
- [x] 用户信息 API（获取用户信息、更新信息、修改密码）
- [x] 单词学习 API（获取今日单词、提交学习结果、搜索单词、单词详情）
- [x] 闯关对战 API（开始闯关、提交闯关结果、获取闯关记录）
- [x] 排行榜 API（获取全服排行榜）
- [x] AI词本 API（获取生词本、添加/移除单词、获取AI生成内容）
- [x] 学习统计 API（学习统计、学习趋势、学习日历）

### 2. 文档编写

- [x] OpenAPI 规范文档（`docs/api.yaml`）
  - 完整的 OpenAPI 3.0 规范
  - 包含 7 个模块、17 个接口定义
  - 完整的请求/响应 Schema 定义
  - JWT 认证配置
  - 统一响应格式定义


### 3. 前端 API 访问层实现

- [x] API 常量配置（`api_constants.dart`）
- [x] HTTP 客户端封装（`api_client.dart`）
  - 统一的 GET/POST/PUT/DELETE 请求封装
  - 自动添加 JWT Token
  - 统一错误处理
- [x] API 异常处理（`api_exception.dart`）
- [x] Service 层实现
  - `auth_service.dart` - 认证服务
  - `word_service.dart` - 单词服务
  - `challenge_service.dart` - 闯关服务
  - `leaderboard_service.dart` - 排行榜服务
  - `wordbook_service.dart` - AI词本服务
  - `study_service.dart` - 学习统计服务
- [x] 数据模型定义
  - `user_model.dart` - 用户模型
  - `word_model.dart` - 单词模型
  - `challenge_model.dart` - 闯关模型
  - `leaderboard_model.dart` - 排行榜模型
  - `wordbook_model.dart` - AI词本模型
  - `study_model.dart` - 学习统计模型

### 4. Mock 数据配置

- [x] 使用 Apifox 导入 OpenAPI 规范
- [x] 配置本地 Mock 服务
- [x] 验证所有接口 Mock 数据返回正常

### 5. 前端页面实现

- [x] 登录页面（`login_screen.dart`）
- [x] 注册页面（`register_screen.dart`）
- [x] 首页（`home_screen.dart`）- 显示今日单词
- [x] 学习页面（`study_screen.dart`）- 单词学习
- [x] 闯关选择页面（`challenge_select_screen.dart`）
- [x] 闯关游戏页面（`challenge_game_screen.dart`）
- [x] 闯关结果页面（`challenge_result_screen.dart`）
- [x] 个人中心页面（`profile_screen.dart`）

### 6. 测试

- [x] Apifox 接口测试（所有接口均返回 Mock 数据）
- [x] 前端 API 调用测试（成功获取单词数据）
- [x] 登录/注册流程测试
- [x] 单词学习流程测试

---

## PR 链接

PR #[23]：https://github.com/xi1xi1/Words/pull/23      
PR #[24]：https://github.com/xi1xi1/Words/pull/24    

---

## 遇到的问题和解决

### 问题 1: Apifox Mock 返回的业务 code 不是 200，导致前端报错

**现象**：Mock 返回 `{"code": 9, ...}`，前端 `api_client` 只认 200-299 的 code，抛出异常。

**解决方案**：修改 `api_client.dart` 的 `_handleResponse` 方法，改为检查 HTTP 状态码（200-299）而非业务 code，成功接收所有 Mock 数据。

### 问题 2: 数据模型字段与 Mock 返回不匹配

**现象**：Mock 返回的字段名是 `newWords`，但模型中用的是 `dailyWords`，导致数据解析失败。

**解决方案**：统一字段名为 `newWords` 和 `reviewWords`，并添加 `null` 安全处理。

### 问题 3: 前端路由配置导致登录页面不显示

**现象**：App 启动后直接进入首页，没有登录页面。

**解决方案**：修改 `app_router.dart` 中的 `initialLocation` 从 `'/'` 改为 `'/login'`。

### 问题 4: 注册成功后跳转失败

**现象**：注册成功后没有跳转到登录页面。

**解决方案**：使用 `Navigator.pushReplacement` 替代 `context.go`，直接跳转到 `LoginScreen`。

### 问题 5: 个人中心页面字段名不匹配

**现象**：`StudyStats` 模型字段与页面使用的字段不一致，导致编译错误。

**解决方案**：根据实际模型字段重新设计个人中心页面，使用 `totalLearned`、`streakDays`、`totalTime` 等正确字段。

---

## 四、心得体会

### 1. API 设计先行

本次实践让我深刻体会到「先设计 API，再开发代码」的重要性。通过 OpenAPI 规范提前定义好接口，前后端可以并行开发，前端使用 Mock 数据就能完成大部分功能开发。

### 2. 统一的响应格式

统一的响应格式（`{code, message, data}`）让前端错误处理变得简单。虽然 Mock 返回的 code 是随机的，但这种统一结构让前端能稳定解析。

### 3. 工具链的使用

- **Apifox**：API 设计、Mock、测试一体化，大大提高了开发效率
- **go_router**：路由管理清晰，但需要注意 `context.go` 的使用场景

### 4. 团队协作

API 文档作为前后端协作的契约，清晰完整的文档能减少沟通成本。本次设计的 OpenAPI 文档可以直接导入 Apifox 生成 Mock 服务，让前端开发完全独立于后端。


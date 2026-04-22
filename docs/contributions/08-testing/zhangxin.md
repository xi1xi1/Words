# 软件测试（前端）个人贡献说明

**姓名**：张欣  
**学号**：2312190333  
**技术栈**：Flutter + Dart  
**日期**：2026-04-22

---

## 1. 本周完成内容（前端测试）

### 1.1 模块化测试覆盖
本周按“分模块 + 尽量全覆盖”的目标，完成了以下测试模块：

- **Model 单元测试**：覆盖核心 JSON 解析与字段兼容逻辑
- **Service 层测试（Mock API）**：使用 Mock HTTP 响应测试接口解析与参数拼装
- **Provider 测试**：覆盖 `SharedPreferences` 本地存储读写、状态流转
- **Widget/页面测试**：覆盖可复用组件 + 认证流程 + 首页 + 学习页关键流程（2~3 条主路径）

### 1.2 Mock API 请求（不依赖后端）
- 通过 `http/testing.dart` 的 `MockClient` + 自定义请求路由器，对 API 请求进行 Mock
- 测试覆盖：成功返回、业务错误（`code != 200`）、空数据等情况

### 1.3 学习页（Study）关键流程 Widget Test
对 `StudyScreen` 覆盖了至少 3 条关键路径：
- Stage 1 选择释义（选择正确选项 -> UI 正确反馈）
- Stage 2 “认识/不认识”按钮提交（进入下一阶段）
- Stage 3 完成后结算弹窗出现（本轮学习完成）

---

## 2. 覆盖率结果

### 2.1 生成命令
在 `frontend/` 目录执行：

```bash
flutter test --coverage
```

### 2.2 报告文件
- `frontend/coverage/lcov.info`

### 2.3 当前覆盖率（线覆盖率）
- **84.61%**（由 `lcov.info` 汇总计算）

---

## 3. 关键改动说明（仅为可测试性注入点，不改业务逻辑）

为支持 Mock API 请求与自动化测试，对网络层做了最小化调整：

- `lib/core/network/api_client.dart`
  - 新增 `ApiClient.debugHttpClient`（仅用于测试注入 HTTP client）
  - 默认行为不变：未注入时仍使用真实 `http.Client()`

- `lib/features/study/screens/study_screen.dart`
  - 为测试注入新增可选参数 `wordService`（默认仍使用真实 `WordService()`）

---

## 4. 测试文件清单（便于验收）

### 4.1 测试工具
- `frontend/test/test_utils.dart`
- `frontend/test/test_prefs.dart`

### 4.2 Model 测试
- `frontend/test/models/word_model_test.dart`
- `frontend/test/models/study_model_test.dart`
- `frontend/test/models/wordbook_model_test.dart`

### 4.3 Service 测试（Mock API）
- `frontend/test/services/auth_service_test.dart`
- `frontend/test/services/word_service_test.dart`
- `frontend/test/services/word_service_more_test.dart`
- `frontend/test/services/study_service_test.dart`
- `frontend/test/services/challenge_service_test.dart`
- `frontend/test/services/challenge_service_more_test.dart`
- `frontend/test/services/leaderboard_service_test.dart`
- `frontend/test/services/wordbook_service_test.dart`

### 4.4 Provider 测试
- `frontend/test/core/providers/user_provider_test.dart`
- `frontend/test/core/providers/wordbook_provider_test.dart`
- `frontend/test/core/providers/wordbook_provider_more_test.dart`

### 4.5 网络层测试
- `frontend/test/core/network/api_client_test.dart`
- `frontend/test/core/network/api_exception_test.dart`

### 4.6 Widget / 页面测试
- `frontend/test/widgets/custom_button_test.dart`
- `frontend/test/widgets/word_card_test.dart`
- `frontend/test/features/auth/login_screen_test.dart`
- `frontend/test/features/auth/register_screen_test.dart`
- `frontend/test/features/home/home_screen_test.dart`
- `frontend/test/features/study/study_screen_test.dart`

---

## 5. README 展示

- 根目录 `README.md`：展示前端测试工作流徽章（CI）与覆盖率概览
- `frontend/README.md`：展示覆盖率细节、命令与报告路径

---

## 6. AI 辅助（加分项）

- 使用工具：Cursor
- Prompt 示例（节选）：
  1. “为 Flutter 的 `ApiClient` 编写单元测试，覆盖：Authorization 头、HTTP 非 2xx、业务 code!=200、401 触发 onUnauthorized、非 Map JSON 响应等场景。使用 `MockClient`，不要依赖真实后端。”
  2. “为 `WordbookProvider`/`WordService` 补充分支测试，覆盖 add/remove/clear、searchWords 的 `data.list`/`data.content` 兼容解析等。”
- 人工修改与校验：
  - 将部分 `expect(() => future, throwsA(...))` 改为 `await expectLater(future, throwsA(...))`，避免异步异常未被捕获
  - 调整 Mock 路由 URL/queryParams 的拼接，使其与实际 `ApiClient` 生成的 URL 完全一致
  - 补充失败场景与边界数据（401、500、空 list、字段缺失）并重新运行 `flutter test --coverage` 验证

---

## 7. 心得体会

本周通过“从底层（Model/Service）到上层（Provider/Widget）”的分层测试方式，把网络依赖通过 Mock 隔离，保证测试稳定可重复运行。同时对学习页等交互复杂页面补充关键路径 Widget Test，兼顾覆盖率与业务关键流程验证。

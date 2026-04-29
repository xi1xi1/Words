# 前端开发贡献说明

**姓名**：张欣  
**学号**：2312190333  
**技术栈**：Flutter + Dart  
**日期**：2026-04-01

---

## 我完成的工作

### 1. 页面开发

| 页面 | 文件路径 | 状态 | 说明 |
|------|----------|------|------|
| 登录页面 | `lib/features/auth/screens/login_screen.dart` | ✅ | 表单验证、密码隐藏/显示、登录跳转 |
| 注册页面 | `lib/features/auth/screens/register_screen.dart` | ✅ | 用户名/密码/邮箱验证、注册流程 |
| 首页 | `lib/features/home/screens/home_screen.dart` | ✅ | 学习卡片、复习卡片、今日推荐单词 |
| 学习页面 | `lib/features/study/screens/study_screen.dart` | ✅ | 三步学习法（选义→例句→认词）、交叉学习队列 |
| 复习页面 | `lib/features/review/screens/review_screen.dart` | ✅ | 四选一复习、自动判题、正确率统计 |
| 闯关选择页面 | `lib/features/challenge/screens/challenge_select_screen.dart` | ✅ | 初级/中级/高级场次选择 |
| 闯关游戏页面 | `lib/features/challenge/screens/challenge_game_screen.dart` | ✅ | 倒计时答题、自动计分 |
| 闯关结果页面 | `lib/features/challenge/screens/challenge_result_screen.dart` | ✅ | 得分展示、积分变化、正确率 |
| 个人中心页面 | `lib/features/profile/screens/profile_screen.dart` | ✅ | 学习数据统计、词库进度、工具入口 |
| 设置页面 | `lib/features/profile/screens/settings_screen.dart` | ✅ | 深色模式、学习目标、学习提醒、自动发音 |
| 排行榜页面 | `lib/features/leaderboard/screens/leaderboard_screen.dart` | ✅ | 今日/本周/总榜切换、前三名特殊展示 |
| 生词本页面 | `lib/features/wordbook/screens/wordbook_screen.dart` | ✅ | 生词列表、移除单词 |
| 离线词库页面 | `lib/features/offline/screens/offline_words_screen.dart` | ✅ | 词库下载管理 |
| 词库选择页面 | `lib/features/wordbook/screens/wordbook_select_screen.dart` | ✅ | 四级/六级/考研/托福词库选择 |
| 最近战绩页面 | `lib/features/challenge/screens/recent_battles_screen.dart` | ✅ | 历史战绩、统计图表 |

---

### 2. 组件/模块封装

| 组件名称 | 文件路径 | 用途 |
|----------|----------|------|
| `CustomButton` | `lib/widgets/custom_button.dart` | 自定义按钮，支持加载状态、多种样式 |
| `CustomCard` | `lib/widgets/custom_card.dart` | 通用卡片容器，统一样式 |
| `WordCard` | `lib/widgets/word_card.dart` | 单词展示卡片，包含单词、音标、释义、例句 |
| `ProgressBar` | `lib/widgets/progress_bar.dart` | 进度条组件，支持百分比显示 |
| `LoadingOverlay` | `lib/widgets/loading_overlay.dart` | 加载遮罩层，用于异步操作时阻止交互 |
| `LoadingIndicator` | `lib/widgets/loading_indicator.dart` | 通用加载动画组件 |

---

### 3. 路由配置

| 文件 | 说明 |
|------|------|
| `lib/app.dart` | 应用入口、主题配置、路由配置 |
| 路由表 | 共配置 15+ 个路由，包括 ShellRoute（底部导航）和全屏页面路由 |

**路由列表**：
- `/` - 首页（ShellRoute）
- `/challenge` - 闯关选择（ShellRoute）
- `/profile` - 个人中心（ShellRoute）
- `/login` - 登录页
- `/register` - 注册页
- `/study` - 学习页
- `/review` - 复习页
- `/challenge-result` - 闯关结果页
- `/leaderboard` - 排行榜
- `/settings` - 设置
- `/wordbook` - 生词本
- `/wordbook-select` - 词库选择
- `/offline-words` - 离线词库
- `/recent-battles` - 最近战绩

---

### 4. 主题与样式

| 文件 | 说明 |
|------|------|
| `lib/core/theme/app_theme.dart` | 浅色/深色主题配置 |
| `lib/core/constants/constants.dart` | 颜色常量、字体常量、API常量 |
| `lib/core/providers/settings_provider.dart` | 主题模式状态管理 |

**主题特点**：
- 支持浅色/深色模式自动切换
- 主色：#4F7CFF（浅色）/ #6D8CFF（深色）
- 辅助色：#6BCB77 / #7EDC8D
- 强调色：#FF9F43 / #FFB86B

---

### 5. API 对接

| Service | 文件路径 | 对接接口 |
|---------|----------|----------|
| `ApiClient` | `lib/services/api_client.dart` | HTTP 请求封装（GET/POST/PUT/DELETE） |
| `AuthService` | `lib/services/auth_service.dart` | 登录、注册、登出 |
| `WordService` | `lib/services/word_service.dart` | 获取今日单词、提交学习结果 |
| `ChallengeService` | `lib/services/challenge_service.dart` | 开始闯关、提交闯关结果 |
| `LeaderboardService` | `lib/services/leaderboard_service.dart` | 获取排行榜 |
| `WordbookService` | `lib/services/wordbook_service.dart` | 生词本增删查 |
| `StudyService` | `lib/services/study_service.dart` | 学习统计、学习趋势 |

**数据模型**：
- `lib/models/user_model.dart`
- `lib/models/word_model.dart`
- `lib/models/challenge_model.dart`
- `lib/models/leaderboard_model.dart`
- `lib/models/wordbook_model.dart`
- `lib/models/study_model.dart`

**错误处理**：
- `lib/core/network/api_exception.dart` - 统一异常处理
- 全局加载状态、错误提示、Toast反馈

---

### 6. 核心功能实现

#### 6.1 学习页面（交叉学习模式）
- 每个单词需要完成 3 轮（选义→例句→认词）
- 单词交叉出现，避免连续背诵同一单词
- 学习队列管理，自动调度下一个单词
- 进度条实时更新，显示单词完成情况

#### 6.2 复习页面
- 四选一选择题模式
- 自动判题，正确/错误视觉反馈
- 正确率统计，完成后显示总结弹窗
- 支持重新复习

#### 6.3 闯关游戏
- 倒计时答题机制
- 每题限时，超时自动提交
- 实时计分，根据正确率和用时计算得分
- 结果页展示积分变化和累计总分

#### 6.4 个人中心
- 学习数据仪表盘（今日学习/复习、累计学习、今日时长）
- 当前词库进度条
- 学习工具入口（生词本、离线词库）
- 设置入口、退出登录

#### 6.5 排行榜
- Tab 切换（今日/本周/总榜）
- 前三名特殊展示（奖杯图标、渐变背景）
- 排名列表，支持排名变化标识

---

### 7. 截图证明

| 页面 | 截图路径 |
|------|----------|
| 登录页 | `docs/design/screenshots/login.png` |
| 注册页 | `docs/design/screenshots/register.png` |
| 首页 | `docs/design/screenshots/home.png` |
| 学习页 | `docs/design/screenshots/study.png` |
| 复习页 | `docs/design/screenshots/review.png` |
| 闯关页 | `docs/design/screenshots/challenge.png` |
| 个人中心 | `docs/design/screenshots/my.png` |
| 设置页 | `docs/design/screenshots/settings.png` |
| 排行榜 | `docs/design/screenshots/leaderboard.png` |
| 生词本 | `docs/design/screenshots/wordbook.png` |

---

## PR 链接

- PR #28：https://github.com/xi1xi1/Words/pull/28  

---

## 遇到的问题和解决

### 问题 1: 学习页面连续背同一个单词

**现象**：初始实现中，每个单词连续完成 3 轮后才进入下一个单词，不符合记忆规律。

**解决方案**：
- 引入学习队列 `_learningQueue`
- 每完成一轮，将 (单词索引, 轮次+1) 添加到队列末尾
- 从队列头部取出下一个单词继续学习
- 实现单词交叉出现，符合间隔重复规律


### 问题 2: 路由配置导致全屏页面无法打开

**现象**：`/leaderboard` 和 `/settings` 路由报错 "no routes for location"。

**解决方案**：
- 确保全屏页面使用 `parentNavigatorKey: rootNavigatorKey`
- 使用 `context.push()` 而非 `context.go()` 进行跳转
- 在 `app.dart` 中将全屏页面放在 ShellRoute 之后

### 问题 3: 复习页面无数据时显示空白

**现象**：复习单词列表为空时，页面显示空白。

**解决方案**：
- 添加空状态处理，显示友好提示
- 提供"返回首页"按钮
- 判断 `reviewWords.isEmpty` 时展示空状态 UI


---

## 心得体会

### 1. 设计驱动开发

本次开发严格遵循 Figma 设计稿，先完成 UI 布局，再对接业务逻辑。这样做的好处是：
- UI 与设计稿高度一致
- 便于发现交互问题并提前调整
- 后期对接 API 时只需替换 Mock 数据

### 2. 组件化思维

封装可复用组件（CustomButton、WordCard、ProgressBar）大大提高了开发效率：
- 统一样式，便于维护
- 减少重复代码
- 一处修改，全局生效

### 3. 学习算法优化

学习页面从最初的"连续背三遍"优化为"交叉学习队列"，体现了对用户体验的思考：
- 符合艾宾浩斯遗忘曲线原理
- 提高记忆效率
- 更接近真实学习场景  

### 4. 路由管理

使用 go_router 管理路由，配合 ShellRoute 实现底部导航栏：
- 全屏页面和 Tab 页面分离
- 返回栈管理清晰
- 支持路由参数传递  

---

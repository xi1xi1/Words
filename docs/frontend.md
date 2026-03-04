# 背了么 —— 前端设计说明

## 一、项目说明

“背了么”是一款面向大学生的背单词 App。  

前端使用 **Flutter** 开发，  
后端使用 **Spring Boot**，  
数据存储使用 **MySQL**。

---

## 二、技术栈

- Flutter
- Dart
- http （网络请求）
- Provider（状态管理）
- SharedPreferences（本地存储）

---

## 三、前端项目结构
lib/
│
├── main.dart # 应用入口
├── app.dart # 路由与主题配置
│
├── core/ # 全局配置
│ ├── constants/ # 常量
│ ├── theme/ # 主题样式
│
├── features/ # 功能模块
│ ├── auth/ # 登录注册
│ ├── home/ # 首页
│ ├── study/ # 标准背词
│ ├── challenge/ # 分级闯关
│ ├── leaderboard/ # 排行榜
│ ├── ai_wordbook/ # AI词本
│
├── services/ # 接口请求封装
├── models/ # 数据模型
└── widgets/ # 公共组件


---

## 四、主要功能

### 1. 登录注册

- 用户注册
- 用户登录
- 保存登录状态

---

### 2. 标准背词

- 卡片式展示单词
- 显示音标、释义
- 支持发音
- 拼写测试

---

### 3. 分级闯关

- 初级 / 中级 / 高级
- 限时答题
- 自动计分

---

### 4. 排行榜

- 显示用户积分排名
- 下拉刷新

---

### 5. AI词本

- 添加生词
- 调用后端接口生成例句
- 展示对话内容

---

## 五、数据交互说明

前端通过 HTTP 请求与 Spring Boot 后端交互。  
后端数据存储在 MySQL 数据库中。  
数据格式采用 JSON 传输。

---

## 六、运行方式

### 1. 环境要求

- 已安装 Flutter SDK
- 已安装 Android Studio 或 VS Code

---

### 2. 安装依赖

在项目根目录执行：

flutter pub get

---

### 3. 启动项目

在项目根目录执行：

flutter run

---

### 4. 注意事项

- 运行前需确保 Spring Boot 后端服务已启动
- 确保 MySQL 数据库连接正常
- 前端接口地址需配置为后端实际运行地址
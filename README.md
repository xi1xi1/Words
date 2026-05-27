# 背了么

[![Backend Coverage](https://codecov.io/gh/xi1xi1/Words/branch/master/graph/badge.svg?flag=backend)](https://codecov.io/gh/xi1xi1/Words)
[![CI](https://github.com/xi1xi1/Words/actions/workflows/ci.yml/badge.svg)](https://github.com/xi1xi1/Words/actions/workflows/ci.yml)
[![Frontend Coverage](https://codecov.io/gh/xi1xi1/Words/branch/master/graph/badge.svg?flag=frontend)](https://codecov.io/gh/xi1xi1/Words)

> 覆盖率（本地 `flutter test --coverage`）：84.61%（线覆盖率）

---

## 团队成员

| 姓名 | 学号 |
|------|------|
| **张欣** | 2312190333 |
| **陈子怡** | 2312190329 |

---

## 团队分工

| 姓名 | 角色 | 主要负责 |
|------|------|----------|
| **张欣** | 前端 | Flutter 页面与公共组件；路由 / 主题 / Provider 状态管理；`ApiClient` 与接口联调；OpenAPI 与 `docs/api.md` 协作；AI 联想记忆等前端展示；前端单元测试、CI 与覆盖率；前端安全加固；前端 Docker / Nginx / Compose 与 GHCR 镜像构建 |
| **陈子怡** | 后端 | Spring Boot 业务 API（认证、学习、闯关、排行榜等）；数据库设计与 `init.sql`、MyBatis；JWT 鉴权与统一响应；火山方舟 AI 服务封装；后端单元测试与 CI；后端安全审查；后端 Dockerfile 与 `docker-compose` 编排 |

---

## 项目简介

**「背了么」** 旨在以更低门槛、更有趣的方式，解决「背单词难以坚持」的问题。支持标准背词、分级闯关积分、全服排行榜与 AI 词本等能力。

---

## 核心功能

| 模式 | 功能描述 |
|------|----------|
| **标准背词** | 卡片式学习，支持释义、发音、拼写测试，满足日常积累 |
| **分级闯关** | 初级 / 中级 / 高级三场，通关获得积分，场次越高单局积分越多 |
| **全服排行榜** | 按用户总积分排名，看得见大家，无实时对战压力 |
| **AI 词本** | 添加生词后由后端调用大模型生成例句与场景对话 |

---

## 目标用户

- **在校大学生**（四六级、考研备考）
- **背单词总放弃的「反复开始者」**

---

## 技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| 前端 | Flutter + Dart | 跨平台 UI，`Provider` 状态管理，`go_router` 路由 |
| 网络 | http | 统一在 `services/` 封装 API 请求 |
| 本地 | SharedPreferences | JWT Token、用户信息缓存 |
| 后端 | Spring Boot 3.x + Java 17 | Controller → Service → Mapper 三层架构 |
| 持久化 | MyBatis + MySQL 8.0 | 手写 SQL，便于排行榜、闯关统计等复杂查询 |
| 认证 | JWT | 无状态登录，除注册/登录外接口需携带 Token |
| AI | 火山引擎 Ark SDK | 例句与场景对话生成（见 `docs/ai-feature.md`） |

---

## 项目结构

```
Words/
├── frontend/          # Flutter 前端
│   └── lib/
│       ├── main.dart
│       ├── core/      # 常量、主题
│       ├── features/  # auth / home / study / challenge / leaderboard / ai_wordbook 等
│       ├── services/  # API 封装
│       ├── models/
│       └── widgets/
├── backend/           # Spring Boot 后端
│   └── src/main/java/com/zychen/backend/
│       ├── controller/、service/、mapper/
│       ├── entity/、dto/、config/、common/
├── docs/              # 架构、接口、数据库等文档
├── init.sql           # 数据库初始化脚本
├── compose.yaml       # Docker 开发环境（可选）
└── CLAUDE.md          # 团队开发规范
```

---

## 快速开始

### 环境要求

| 组件 | 版本建议 |
|------|----------|
| JDK | 17+ |
| Maven | 3.8+ |
| MySQL | 8.0+ |
| Flutter SDK | ^3.9.2 |
| Android Studio / VS Code | 任选，用于 Flutter 调试 |

### 1. 初始化数据库

```bash
# 创建库并导入表结构与基础数据
mysql -u root -p < init.sql
```

数据库名默认为 **`beileme`**。核心表包括：`user`、`word`、`user_word`、`battle_record`、`study_record` 等，详见 [docs/database.md](docs/database.md)。

### 2. 启动后端

1. 在 `backend/src/main/resources/` 下配置数据源（如 `application-dev.yml`），填写 MySQL 地址与账号密码。  
2. 使用 IDE 运行主类 `BackendApplication`，或在 `backend/` 目录执行：

```bash
mvn clean install
mvn spring-boot:run
```

默认服务地址：`http://localhost:8080`，接口前缀：`/api`（示例：`http://localhost:8080/api/auth/login`）。

### 3. 启动前端

```bash
cd frontend
flutter pub get
flutter run
```

**注意：** 运行前请确保后端已启动，且 MySQL 连接正常。将 `frontend/lib/core/constants/api_constants.dart` 中的 `baseUrl` 改为你本机或局域网的后端地址（开发环境示例：`http://172.20.10.2:8080/api`）。

### 4. Docker 一键环境（可选）

复制 `.env.example` 为 `.env` 并填写密码后：

```bash
docker compose -f compose.yaml --env-file .env up -d
```

将启动 MySQL、Redis、后端与 Flutter Web（Nginx）等容器，详见 `compose.yaml` 内注释。

---

## 接口约定

- **风格：** RESTful，`/api` 前缀  
- **认证：** 登录成功后返回 JWT，请求头 `Authorization: Bearer <token>`  
- **统一响应：**

```json
{
  "code": 200,
  "message": "success",
  "data": {}
}
```

| code | 含义 |
|------|------|
| 200 | 成功 |
| 400 | 参数错误 |
| 401 | 未认证 |
| 403 | 无权限 |
| 500 | 服务器错误 |

完整接口列表见 [docs/api.md](docs/api.md)。

---

## 相关文档

| 文档 | 说明 |
|------|------|
| [docs/architecture.md](docs/architecture.md) | 系统架构与模块划分 |
| [docs/frontend.md](docs/frontend.md) | 前端目录与功能说明 |
| [docs/backend.md](docs/backend.md) | 后端分层、数据库与运行方式 |
| [docs/database.md](docs/database.md) | ER 与表结构详情 |
| [docs/api.md](docs/api.md) | API 接口定义 |
| [docs/deployment.md](docs/deployment.md) | Railway 云平台部署说明 |
| [docs/design-spec.md](docs/design-spec.md) | UI 设计规范 |
| [CLAUDE.md](CLAUDE.md) | 代码与协作规范 |

---

## 设计稿

- **Figma：** https://www.figma.com/make/tgyOxxZ9QKeIiUhGVRX2GV/%E8%83%8C%E5%8D%95%E8%AF%8Dapp?t=a35DJGc2SghKkhS6-1  
- **v0：** https://v0.app/chat/app-vnAAuRusc91?ref=B6YOZS  

---

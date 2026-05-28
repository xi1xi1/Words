# 背了么 — 云平台部署说明

本文档记录团队将 **「背了么」**（Flutter Web + Spring Boot + MySQL）部署到 **Railway** 的完整流程，与仓库内 `backend/Dockerfile`、`frontend/Dockerfile` 及当前线上环境一致。

---

## 1. 平台选择

| 平台 | 本项目使用情况 |
|------|----------------|
| **Railway** | ✅ **已采用**：支持 Docker、MySQL 插件、GitHub 自动部署、自动生成 HTTPS 域名 |
| Vercel | 未使用（更适合静态站；Flutter Web 需 Docker/Nginx） |
| Render | 未使用（可与 Railway 类似，流程可参考） |
| 阿里云 / 腾讯云 | 未使用（国内访问更快，适合正式生产） |

**选型理由：** 后端、前端、数据库均可放在同一 Railway 项目内；仓库已有 Dockerfile，与课程 Docker 作业衔接；配置比 K8s 简单。

---

## 2. 架构概览

```
用户浏览器
    │  HTTPS
    ▼
┌──────────────────────────────────────────────────────────┐
│  Frontend（Flutter Web + Nginx）                          │
│  https://words-production-371b.up.railway.app            │
│  端口 8080                                                │
└──────────────┬───────────────────────────────────────────┘
               │  HTTPS  /api/*
               ▼
┌──────────────────────────────────────────────────────────┐
│  Backend（Spring Boot 17 + MyBatis）                      │
│  https://lucid-recreation-production.up.railway.app      │
│  API Base：https://.../api                                │
│  端口 8080，健康检查 /health（以实际配置为准）              │
└──────────────┬───────────────────────────────────────────┘
               │  内网 mysql.railway.internal:3306
               ▼
┌──────────────────────────────────────────────────────────┐
│  MySQL 8.0（Railway Database 插件）                        │
│  库名 railway                                             │
└──────────────────────────────────────────────────────────┘
```

**GitHub 仓库：** [xi1xi1/Words](https://github.com/xi1xi1/Words)  
**自动部署分支：** `master`（Railway 连接 GitHub 后，push 到 `master` 触发构建）

---

## 3. Railway 项目与服务

在 [railway.app](https://railway.app) 创建项目 **Deploy from GitHub repo**，选中本仓库后，依次添加三个服务，并在控制台完成 **Root Directory**、**Variables**、**Public Networking（Generate Domain）** 等配置：

| 服务 | 类型 | Root Directory | 构建方式 |
|------|------|----------------|----------|
| MySQL | Database → Add MySQL | — | 托管数据库 |
| Backend | 同一仓库 | `backend` | `backend/Dockerfile` |
| Frontend | 同一仓库 | `frontend` | `frontend/Dockerfile` |

每个 Web 服务在 **Settings → Networking → Generate Domain** 开启公网访问（Railway 自动生成 HTTPS 域名）。

本项目 **未使用** `railway.toml`、`vercel.json`；部署依赖控制台服务配置 + 各目录下 Dockerfile 构建。

### 3.1 当前线上地址

| 服务 | 公网地址 |
|------|----------|
| 前端 | https://words-production-371b.up.railway.app |
| 后端 | https://lucid-recreation-production.up.railway.app |
| 后端 API Base URL | https://lucid-recreation-production.up.railway.app/api |
| 后端健康检查 | https://lucid-recreation-production.up.railway.app/health |

> 本项目后端提供独立 `GET /health` 端点（`HealthController`），返回 `{"status":"UP"}`；若后续改为 Actuator，请以实际后端健康检查配置为准（如 `/actuator/health`）。

---

## 4. 数据库初始化

Railway MySQL 默认库名多为 **`railway`**（与本地 `beileme` 不同）。

1. 在 MySQL 服务 **Variables** 或 **Connect** 中查看连接信息（内网主机、端口、用户、密码、库名）。
2. 使用根目录 **`railway.sql`** 导入（由 `backup-beileme-*.sql` 改编：去掉 `CREATE DATABASE beileme`，改为 `USE railway;`）。
3. 导入方式任选其一：
   - Railway CLI：`railway connect MySQL`（本机需安装 `mysql` 客户端）
   - 公网代理 + `mysqlsh` / `mysql`：使用 Variables 中的 `MYSQL_PUBLIC_URL` 或 TCP Proxy 地址
4. 验证：应存在表 `user`、`word`、`user_word`、`battle_record`、`study_record`，词库约 3000+ 条。

---

## 5. 环境变量配置

在 **Backend 服务 → Variables** 中配置。**数据库密码、JWT 密钥、ARK API Key 等敏感信息只配置在 Railway Variables，不提交到 GitHub。**

### 5.1 数据库与认证

| 变量名 | 说明 | 配置值（示例 / 占位） |
|--------|------|----------------------|
| `SPRING_DATASOURCE_URL` | JDBC 连接（内网 + 库名 `railway`） | `jdbc:mysql://mysql.railway.internal:3306/railway?useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true&useUnicode=true&characterEncoding=UTF-8` |
| `SPRING_DATASOURCE_USERNAME` | 数据库用户 | `root` |
| `SPRING_DATASOURCE_PASSWORD` | 数据库密码 | 从 MySQL 服务 Variables 复制，**勿写入 Git** |
| `JWT_SECRET` | JWT 签名（UTF-8 至少 32 字节） | 随机长字符串，**勿写入 Git** |
| `JWT_EXPIRATION` | Token 有效期（毫秒） | 如 `86400000`（24 小时） |
| `SPRING_PROFILES_ACTIVE` | 运行环境 | `production` |

### 5.2 跨域（CORS）

| 变量名 | 说明 | 配置值 |
|--------|------|--------|
| `APP_CORS_ALLOWED_ORIGINS` | 允许的前端 Origin | `https://words-production-371b.up.railway.app` |
| `APP_CORS_MERGE_LOCALHOST_PATTERNS` | 生产环境关闭 localhost 合并 | `false` |

### 5.3 MyBatis（生产必配）

| 变量名 | 说明 | 配置值 |
|--------|------|--------|
| `MYBATIS_CONFIGURATION_MAP_UNDERSCORE_TO_CAMEL_CASE` | 数据库下划线字段 → Java 驼峰属性 | `true` |
| `MYBATIS_PLUS_CONFIGURATION_MAP_UNDERSCORE_TO_CAMEL_CASE` | 同上（Railway 实际配置项） | `true` |
| `MYBATIS_MAPPER_LOCATIONS` | XML Mapper 扫描路径 | `classpath*:mapper/*.xml` |
| `MYBATIS_PLUS_MAPPER_LOCATIONS` | 同上（Railway 实际配置项） | `classpath*:mapper/*.xml` |

**MyBatis 生产配置说明：**

本地开发可在 `application.yml` 中配置 MyBatis，但该文件在 `.gitignore` 中，**不会打进生产 Docker 镜像**。因此生产环境必须在 Railway Variables 中显式配置：

1. **下划线转驼峰**（`map-underscore-to-camel-case=true`）  
   否则 `user_word.word_id` 无法映射到 Java 的 `wordId`，`/api/words/daily` 等接口可能返回 **500**。

2. **XML Mapper 扫描路径**（`mapper-locations=classpath*:mapper/*.xml`）  
   否则 `backend/src/main/resources/mapper/` 下的 XML 不会加载，调用 XML 中定义的 SQL 时出现：  
   `Invalid bound statement (not found): com.zychen.backend.mapper.StudyRecordMapper.selectByUserIdAndStudyDate`  
   典型表现：`GET /api/words/daily` 正常，但 `POST /api/words/learn` 返回 **500**。

### 5.4 AI 词本（火山方舟）

| 变量名 | 说明 | 配置值 |
|--------|------|--------|
| `ARK_API_KEY` | 火山方舟 API Key | **勿写入 Git**，仅在 Railway 配置 |
| `ARK_ENDPOINT_ID` | 方舟接入点 ID | **勿写入 Git**，仅在 Railway 配置 |

MySQL 服务 Variables 由 Railway 自动生成（如 `MYSQLHOST`、`MYSQLPASSWORD` 等）。若 Backend 中使用 `${{MySQL.xxx}}` 引用为空，请从 MySQL 服务 **手动复制** 到 `SPRING_DATASOURCE_*`。

---

## 6. 前端 API 地址

部署前修改并 **push 到 `master`**：

**文件：** `frontend/lib/core/constants/api_constants.dart`

```dart
static const String baseUrl =
    'https://lucid-recreation-production.up.railway.app/api';
```

要求：

- 使用 **`https`**
- 末尾包含 **`/api`**
- 不要写前端自己的域名（API 应指向后端）

修改后 Railway 会重新构建 Frontend 镜像；浏览器若仍请求旧地址，请 **硬刷新** 或清除站点数据 / Service Worker 缓存。

---

## 7. 自动部署（Git → Railway）

1. Railway 项目 **Settings** 连接 GitHub 仓库 `xi1xi1/Words`。
2. Backend / Frontend 分别设置 **Root Directory**，并在 **Networking** 中开启公网域名。
3. 部署分支设为 **`master`**。
4. 每次 `git push origin master` 后，Railway 自动：
   - 使用 `backend/Dockerfile` 或 `frontend/Dockerfile` 多阶段构建
   - 发布新容器并切换流量

**构建说明：**

- **Backend：** Maven 打包 → JRE 17 运行 `app.jar`；Dockerfile 健康检查探测 `GET /health`（以实际后端健康检查配置为准）
- **Frontend：** `flutter build web --release` → Nginx 托管静态资源，监听 8080

仓库另有 `.github/workflows/docker.yml` 可向 GHCR 推送镜像，供 `compose.prod.yaml` 使用；**Railway 线上部署不依赖该工作流**，直接使用仓库内 Dockerfile。

---

## 8. 域名与 HTTPS

- Railway 为每个服务自动生成 `*.up.railway.app` 域名，并启用 **HTTPS**，无需额外证书。
- 自定义域名（可选）：服务 **Settings → Custom Domain** 按提示配置 CNAME。

---

## 9. 部署验证清单

| 步骤 | 操作 | 期望结果 |
|------|------|----------|
| 1 | 浏览器打开 `https://lucid-recreation-production.up.railway.app/health` | `{"status":"UP"}`（若已改为 Actuator，以实际路径为准） |
| 2 | 打开 `https://words-production-371b.up.railway.app` | 显示登录/注册页 |
| 3 | 注册新用户（密码 ≥8 位，含字母+数字，填写邮箱） | 返回 200 与 token |
| 4 | 登录后进入首页 | `GET /api/words/daily` 为 **200**（非 500） |
| 5 | 提交一次学习结果 | `POST /api/words/learn` 为 **200**（非 500） |
| 6 | F12 Network | 请求 host 为 `lucid-recreation-production.up.railway.app`，无 Mixed Content |
| 7 | 未登录时 `wordbook/list` | 可能 **401**，属正常（需登录后带 Token） |

---

## 10. 常见问题

### 10.1 前端仍请求 `http://172.20.10.2:8080/api`

- **原因：** 线上 Frontend 镜像由旧代码构建，或浏览器缓存 / Service Worker。
- **处理：** 确认 `api_constants.dart` 中 `baseUrl` 为 `https://lucid-recreation-production.up.railway.app/api`，已 push 到 `master` 并等待 Frontend 重新部署；使用无痕窗口或清除站点数据。

### 10.2 `Failed to obtain JDBC Connection` / 注册登录 500

- **原因：** Backend 未配置 `SPRING_DATASOURCE_*` 或密码错误。
- **处理：** 对照 MySQL 服务 Variables 手动填写 `SPRING_DATASOURCE_URL`、`SPRING_DATASOURCE_USERNAME`、`SPRING_DATASOURCE_PASSWORD`。

### 10.3 `GET /api/words/daily` 500

- **原因：** 生产环境未开启 MyBatis 下划线转驼峰，`user_word.word_id` 无法映射到 Java 的 `wordId`。
- **处理：** 在 Railway Backend Variables 中配置：
  - `MYBATIS_CONFIGURATION_MAP_UNDERSCORE_TO_CAMEL_CASE=true`
  - `MYBATIS_PLUS_CONFIGURATION_MAP_UNDERSCORE_TO_CAMEL_CASE=true`
  保存后重新部署 Backend。

### 10.4 `POST /api/words/learn` 500

- **现象：** `GET /api/words/daily` 正常返回 200，但提交学习结果时报 500。
- **日志：** `Invalid bound statement (not found): com.zychen.backend.mapper.StudyRecordMapper.selectByUserIdAndStudyDate`
- **原因：** 生产环境未加载 `StudyRecordMapper.xml`（未配置 XML Mapper 扫描路径）。
- **处理：** 在 Railway Backend Variables 中配置：
  - `MYBATIS_MAPPER_LOCATIONS=classpath*:mapper/*.xml`
  - `MYBATIS_PLUS_MAPPER_LOCATIONS=classpath*:mapper/*.xml`
  然后重新部署 Backend。

### 10.5 CORS 错误

- **原因：** `APP_CORS_ALLOWED_ORIGINS` 未包含前端 HTTPS 域名。
- **处理：** 设为 `https://words-production-371b.up.railway.app`（完整 Origin，无路径）。

### 10.6 导入用户无法登录

- 备份中用户密码为 BCrypt 哈希，明文未知。
- **处理：** 在线上 **注册新账号** 用于演示。

---

## 11. 目录与配置文件对照

```
Words/
├── backend/
│   ├── Dockerfile                    # Railway 后端构建
│   └── src/main/resources/
│       └── mapper/                   # MyBatis XML Mapper（如 StudyRecordMapper.xml）
├── frontend/
│   ├── Dockerfile                    # Flutter Web + Nginx
│   ├── nginx.conf
│   └── lib/core/constants/
│       └── api_constants.dart        # 生产 baseUrl
├── railway.sql                       # Railway MySQL 导入脚本
├── init.sql                          # 本地 Docker / 开发初始化
├── .env.example                      # 本地与 Compose 环境变量说明（非 Railway 生产配置）
├── compose.yaml                      # 本地 Docker 编排（可选）
└── docs/
    └── deployment.md                 # 本文档
```

**配置管理说明：**

- `backend/src/main/resources/application.properties` 与 `application.yml` 在 `.gitignore` 中，**未提交到 GitHub**，生产镜像通常不包含本地数据库密码等敏感信息。
- **`backend/src/main/resources/mapper/`** 下存放 MyBatis XML Mapper 文件（如 `StudyRecordMapper.xml`、`BattleRecordMapper.xml`），需配合 Railway Variables 中的 `MYBATIS_MAPPER_LOCATIONS` 才能在生产环境加载。
- **生产环境主要通过 Railway Variables 管理配置**，避免将数据库密码、`JWT_SECRET`、`ARK_API_KEY` 等敏感信息提交到 GitHub。

本项目 **未使用** `vercel.json` / `railway.toml`；Railway 通过控制台配置服务、Variables、Public Networking，并使用 `frontend/Dockerfile` 与 `backend/Dockerfile` 构建。

---

## 12. 相关文档

| 文档 | 说明 |
|------|------|
| [docs/contributions/11-docker/chenziyi.md](contributions/11-docker/chenziyi.md) | Dockerfile 与 Compose |
| [docs/contributions/12-cloud/chenziyi.md](contributions/12-cloud/chenziyi.md) | 云平台部署个人贡献说明（后端 / Railway 全栈） |
| [docs/contributions/12-cloud/zhangxin.md](contributions/12-cloud/zhangxin.md) | 云平台部署个人贡献说明（前端 API 地址 / 线上验证） |
| [docs/backend.md](backend.md) | 后端运行与配置 |
| [.env.example](../.env.example) | 环境变量命名对照 |

---

**维护：** 陈子怡（2312190329）、张欣（2312190333）  
**最后更新：** 2026-05-27

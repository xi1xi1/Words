# 云服务部署贡献说明

姓名：张欣  
学号：2312190333  
日期：2026-05-27  

## 我完成的工作

### 1. 平台选择

- 使用平台：**Railway**（与团队一致；前端为 Flutter Web + Nginx 容器，Root Directory = `frontend`）
- 分工说明：后端同学完成 Railway 项目创建、MySQL/Backend 服务与环境变量；我负责**前端生产 API 地址**、**前端镜像构建配置联调**与**线上验证**。

### 2. 部署配置

- [x] 配置文件编写（`frontend/Dockerfile`、`frontend/nginx.conf`、`frontend/.dockerignore`；第 11 周 Docker 作业已提交；云平台使用 Railway 控制台 + Dockerfile，未单独新增 `vercel.json` / `railway.toml`）
- [x] 环境变量配置（前端 API 地址通过代码配置，见下；敏感变量由后端在 Railway Backend Variables 配置，前端仓库不提交密钥）
- [x] 自动部署配置（GitHub 仓库 `xi1xi1/Words` 连接 Railway，`master` 分支 push 后自动构建 `frontend/Dockerfile` 并发布）

#### 2.1 生产 API 地址（前端必改）

**文件：** `frontend/lib/core/constants/api_constants.dart`

```dart
static const String baseUrl =
    'https://lucid-recreation-production.up.railway.app/api';
```

- 由本地 `http://172.20.10.2:8080/api` 改为线上后端 **HTTPS** 地址，避免浏览器 Mixed Content。
- push 到 `master` 后 Railway 重新构建 Frontend 服务；若仍请求旧地址，需硬刷新或清除站点缓存。

#### 2.2 前端 Railway 服务要点（协作确认）

| 配置项 | 值 |
|--------|-----|
| Root Directory | `frontend` |
| 构建 | `frontend/Dockerfile` 多阶段：`flutter build web` + Nginx |
| 公网域名 | https://words-production-371b.up.railway.app |
| 容器端口 | 8080（Nginx） |
| 健康检查 | `frontend/nginx.conf` 提供 `GET /health` |

后端需将 `APP_CORS_ALLOWED_ORIGINS` 设为前端 Origin：`https://words-production-371b.up.railway.app`（由后端同学配置）。

#### 2.3 部署验证（本人执行）

| 步骤 | 结果 |
|------|------|
| 打开 https://words-production-371b.up.railway.app | 显示登录/注册页 |
| 打开 https://words-production-371b.up.railway.app/health | 返回 `healthy` |
| F12 Network 登录后请求 | Host 为 `lucid-recreation-production.up.railway.app`，协议 HTTPS |

### 3. 问题解决

- **遇到的问题：** 线上页面仍请求 `http://172.20.10.2:8080/api`，控制台报 Mixed Content。  
  **解决方案：** 修改 `api_constants.dart` 中 `baseUrl` 为 Railway 后端 HTTPS 地址并 push，等待 Frontend 服务重新部署后无痕访问验证。

- **遇到的问题：** 登录后接口 CORS 失败。  
  **解决方案：** 与后端确认 `APP_CORS_ALLOWED_ORIGINS` 包含 `https://words-production-371b.up.railway.app`（完整 Origin，无尾斜杠）。

## PR 链接

- 团队部署 PR #88: https://github.com/xi1xi1/Words/pull/88  
- 本人本次提交：生产 `baseUrl` + `docs/contributions/12-cloud/zhangxin.md`（见当前分支 PR）

## 在线地址

https://words-production-371b.up.railway.app

（后端 API：https://lucid-recreation-production.up.railway.app/api）

## 心得体会

云服务作业让我体会到：前端“部署”不仅是把页面放上网，还要保证 **API 基址、HTTPS、CORS** 与后端一致。Flutter Web 的 `baseUrl` 在编译期打进镜像，改地址必须重新构建 Frontend 服务。与第 11 周 Docker 作业衔接后，Railway 只需指定 `frontend` 目录和 Dockerfile 即可自动发布；排错时结合浏览器 Network 与后端 `/health` 比只看 UI 更快定位问题。

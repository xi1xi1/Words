# 云服务部署贡献说明

姓名：陈子怡  
学号：2312190329  
日期：2026-05-27  

## 我完成的工作

### 1. 平台选择

- 使用平台：**Railway**（支持 Docker、MySQL 插件、GitHub 自动部署、自动生成 HTTPS 域名）

### 2. 部署配置

- [x] 配置文件编写（`backend/Dockerfile`、`frontend/Dockerfile`；未使用 `railway.toml` / `vercel.json`；编写 `docs/deployment.md`、`railway.sql`）
- [x] 环境变量配置（Railway Backend Variables：`SPRING_DATASOURCE_*`、`JWT_SECRET`、`JWT_EXPIRATION`、`APP_CORS_*`、`MYBATIS_*`、`ARK_*` 等；敏感信息仅保存在 Railway，不提交 GitHub）
- [x] 自动部署配置（GitHub 仓库 `xi1xi1/Words`，分支 `master`；Backend Root Directory = `backend`，Frontend Root Directory = `frontend`；Public Networking 开启公网域名）

### 3. 问题解决

- **遇到的问题：** 前端仍请求本地 IP `http://172.20.10.2:8080/api`，浏览器报 Mixed Content。  
  **解决方案：** 修改 `frontend/lib/core/constants/api_constants.dart` 中 `baseUrl` 为 `https://lucid-recreation-production.up.railway.app/api`，push 到 `master` 重新部署 Frontend，并清除浏览器缓存 / Service Worker。

- **遇到的问题：** 注册或登录返回 500，日志 `Failed to obtain JDBC Connection`。  
  **解决方案：** 在 Railway Backend Variables 手动配置 `SPRING_DATASOURCE_URL`、`SPRING_DATASOURCE_USERNAME`、`SPRING_DATASOURCE_PASSWORD`（内网 `mysql.railway.internal`，库名 `railway`）。

- **遇到的问题：** 登录后 `GET /api/words/daily` 返回 500。  
  **解决方案：** 生产环境未开启 MyBatis 下划线转驼峰，`user_word.word_id` 无法映射到 `wordId`；配置 `MYBATIS_CONFIGURATION_MAP_UNDERSCORE_TO_CAMEL_CASE=true` 与 `MYBATIS_PLUS_CONFIGURATION_MAP_UNDERSCORE_TO_CAMEL_CASE=true` 后重新部署 Backend。

- **遇到的问题：** `GET /api/words/daily` 正常，但 `POST /api/words/learn` 返回 500，日志 `Invalid bound statement (not found): com.zychen.backend.mapper.StudyRecordMapper.selectByUserIdAndStudyDate`。  
  **解决方案：** 配置 `MYBATIS_MAPPER_LOCATIONS=classpath*:mapper/*.xml` 与 `MYBATIS_PLUS_MAPPER_LOCATIONS=classpath*:mapper/*.xml`，使 `StudyRecordMapper.xml` 在生产环境加载。

- **遇到的问题：** 前端跨域失败。  
  **解决方案：** 配置 `APP_CORS_ALLOWED_ORIGINS=https://words-production-371b.up.railway.app`，`APP_CORS_MERGE_LOCALHOST_PATTERNS=false`。

## PR 链接

- PR #88: https://github.com/xi1xi1/Words/pull/88

## 在线地址

https://words-production-371b.up.railway.app

（后端 API：https://lucid-recreation-production.up.railway.app/api）

## 心得体会

本次部署让我认识到，云平台上线不仅是把 Docker 镜像跑起来，还要打通数据库内网连接、前端 API 地址、CORS、以及 MyBatis 生产配置（驼峰映射与 XML Mapper 路径）整条链路。敏感信息应全部放在 Railway Variables 中管理，避免提交到 GitHub。Railway 与 GitHub 联动后，push 到 `master` 即可自动发布，适合课程演示；排错时结合 `/health`、浏览器 Network 与 Backend 部署日志，比只看前端 500 更高效。

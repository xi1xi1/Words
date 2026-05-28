# Docker 部署贡献说明

姓名：陈子怡  
学号：2312190329
日期：2026-05-13  


---

## 我完成的工作

### 1. Dockerfile 编写

- [x] 后端 Dockerfile（多阶段构建：`maven` 打包 → `eclipse-temurin:17-jre-alpine`；非 root 用户；`/health` 健康检查；`EXPOSE 8080`）
- [x] 后端 `.dockerignore`（排除 `target/`、`.git`、`.env`、`htmlReport/` 等）

补充说明（与仓库一致）：

- 后端新增 `GET /health`（`HealthController`），供 Docker / Compose 健康检查使用（与 JWT 拦截的 `/api/**` 分离）。
- 根目录 `.gitignore` 已调整，允许提交各模块 `.dockerignore`。

### 2. Compose 配置

- [x] 开发环境 `compose.yaml`（MySQL + Redis + 后端 `mvn spring-boot:run` 热跑 + 前端 Nginx 镜像；命名卷 `mysql-data` / `maven-repo`）
- [x] 生产环境 `compose.prod.yaml`（MySQL 密码 `secrets/mysql_root_password.txt`、后端/前端 GHCR 镜像、资源限制、`wget`/`mysqladmin` 健康检查）
- [x] 根目录 `docker-compose.yml`（本机一键：MySQL + Redis + Dockerfile 后端 + 前端；与上两者共用 `name: beileme` 与 `mysql-data` 持久化）
- [x] 健康检查：后端 `/health`；前端 Nginx `/health`；MySQL `mysqladmin ping`

### 3. 自动化部署

- **选择了选项 A**：GitHub Actions 构建并推送镜像到 **GHCR**；另附 **`deploy.sh`** 用于生产 `compose.prod.yaml` 一键 `pull` + `up`
- **具体内容**：
  - `.github/workflows/docker.yml`：`dorny/paths-filter` 按变更分别构建 **backend** / **frontend**；镜像名强制小写 `ghcr.io/<owner>/<repo>/backend|frontend`；`build-push-action` + GHA cache；**Trivy** 扫描 `CRITICAL/HIGH`（当前 `exit-code: 0` 便于课程通过，上线前可改为失败即中断）。
  - `deploy.sh`：`docker compose -f compose.prod.yaml pull && up -d`（需已配置 `.env`、`secrets`、且能拉取 GHCR 镜像）。

### 4. 其他与 Docker 相关的仓库改动

- [x] `.env.example`：补充 `BACKEND_IMAGE`、`FRONTEND_IMAGE`、`FRONTEND_PORT`、`FRONTEND_PUBLISH_PORT`、`BACKEND_PUBLISH_PORT` 等与 Compose 对齐的说明。
- [x] `secrets/README.md`：说明 `mysql_root_password.txt` 的创建方式（生产 Compose 使用）。
- [x] `.github/workflows/ci.yml`：去掉慢的 `apt-get install mysql-client`，改为 **`docker run --network host mysql:8.0`** 执行根目录 `init.sql`，加速 CI 初始化测试库。

---

## PR 链接

- PR #【81】: https://github.com/xi1xi1/Words/pull/81

---

## 遇到的问题和解决

1. **问题**：PowerShell 下 `mysqldump ... > backup.sql` 中文乱码。  
   **解决**：不在宿主机用 `>` 重定向；在容器内 `mysqldump -r /tmp/x.sql` 后 `docker cp` 出文件；或提供 `scripts/backup-mysql.ps1`。

2. **问题**：后端镜像 `chown app:app` 失败。  
   **解决**：Alpine 先 `addgroup` 再 `adduser -G app`，保证组存在后再 `chown`。

3. **问题**：CI 中 `apt-get update` 安装 `mysql-client` 极慢或卡住。  
   **解决**：用官方 `mysql:8.0` 镜像自带客户端 + `docker run --network host` 执行 `init.sql`，避免依赖 Ubuntu 源。

4. **问题**：`ChallengeServiceImplTest` 期望选项为释义 `m1`，实际为单词 `w1`。  
   **解决**：测试中 `ObjectMapper` 改为 `@Spy` 真实实例，使 `firstMeaning` 能解析 `meaning` JSON。


---

## AI 使用情况

- **使用了哪些 Prompt**（示例，请按真实修改）：  
  - 为[Spring Boot] 后端创建生产级Dockerfile：
   - 使用多阶段构建减小镜像体积（目标< 200MB）
   - 基础镜像使用Alpine 或slim 变体
   - 非root 用户运行
   - 健康检查端点/health
   - 暴露端口[8080]
   - 包含.dockerignore 文件。  
  - CI 卡住、`mysqldump` 乱码、单测失败等排错类提问。

- **AI 帮助解决了哪些问题**（示例）：  
  - 梳理作业要求与当前仓库（Flutter + Spring Boot + MySQL）的对应关系。  
  - 起草/调整 Dockerfile、Compose、`docker.yml`、`deploy.sh`、`.env.example` 等文件结构。  
  - 分析测试失败与编码问题原因并给出修改建议。

---

## 心得体会


通过本次 Docker 化，理解了 **「镜像构建」与「编排运行」** 的分工：Dockerfile 负责可复现的构建产物与非 root、健康检查；Compose 负责多容器网络、卷持久化与环境变量/密钥注入；CI/CD 则把镜像交付到 GHCR 并做基础安全扫描。与直接在物理机安装相比，容器更利于环境一致与回滚，但也需要注意 **卷勿随意 `down -v`**、以及国内网络下 **镜像拉取与 apt 源** 带来的耗时问题。

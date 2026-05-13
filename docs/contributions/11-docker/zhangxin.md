# Docker 部署贡献说明

姓名：张欣  
学号：2312190333  
角色：前端  
日期：2026-05-13

## 我完成的工作

### 1. Dockerfile 编写

- [x] 前端 Dockerfile（多阶段构建）
- [x] 前端 `.dockerignore` 文件
- [x] 前端 Nginx 静态资源部署配置
- [x] 前端容器健康检查配置
- [ ] 后端 Dockerfile（非本人负责）

#### 前端 Dockerfile 说明

本次部署中，我负责将 Flutter 前端项目容器化。前端镜像采用多阶段构建：

1. 第一阶段使用 Flutter 镜像执行 `flutter pub get` 和 `flutter build web --release`，生成 Web 静态资源。
2. 第二阶段使用 `nginxinc/nginx-unprivileged:1.27-alpine` 托管 `build/web` 目录下的静态文件。
3. 使用非 root Nginx 镜像运行前端服务，降低容器运行风险。
4. 暴露容器内 `8080` 端口，并通过 `/health` 提供健康检查。

相关文件：

- `frontend/Dockerfile`
- `frontend/.dockerignore`
- `frontend/nginx.conf`

### 2. Compose 配置

- [x] 前端开发环境 `compose.yaml`
- [x] 前端生产环境 `compose.prod.yaml`
- [x] 前端健康检查配置
- [x] 前端生产环境资源限制配置
- [ ] 后端与数据库 Compose 配置（非本人负责）

#### Compose 配置说明

我完成了前端服务在 Docker Compose 中的独立配置：

- 开发环境 `compose.yaml`：使用 `./frontend` 作为构建上下文，构建本地前端镜像 `beileme-frontend:dev`，并将宿主机 `5173` 端口映射到容器内 `8080` 端口。
- 生产环境 `compose.prod.yaml`：使用 GHCR 中的前端镜像 `ghcr.io/${GITHUB_REPOSITORY}/frontend:${VERSION}`，配置自动重启、健康检查和内存资源限制。

相关文件：

- `compose.yaml`
- `compose.prod.yaml`

### 3. 自动化部署

- 选择了选项 A：GitHub Actions 构建并推送镜像到 GHCR。
- 具体内容：完成前端镜像自动构建、标签生成、推送到 GitHub Container Registry，并集成 Trivy 镜像漏洞扫描。

#### GitHub Actions 配置说明

我新增了前端 Docker 镜像构建工作流：

- 触发条件：推送到 `main` / `master` 分支，且修改了 `frontend/**` 或 `.github/workflows/frontend-docker.yml`。
- 构建上下文：`./frontend`
- Dockerfile：`./frontend/Dockerfile`
- 镜像仓库：`ghcr.io/${{ github.repository }}/frontend`
- 镜像标签：`latest` 和 `sha-${{ github.sha }}`
- 安全扫描：使用 `aquasecurity/trivy-action` 扫描 `CRITICAL` / `HIGH` 级别漏洞。

相关文件：

- `.github/workflows/frontend-docker.yml`

## 前端部署检查清单

### 基础配置

- [x] 前端 Dockerfile 可用于构建 Flutter Web 镜像
- [x] 前端静态资源通过 Nginx 托管
- [x] 前端服务可通过浏览器访问，默认地址为 `http://localhost:5173`
- [x] 前端健康检查路径 `/health` 已配置
- [ ] `docker compose -f compose.yaml up -d --build` 运行截图待补充
- [ ] 浏览器访问前端页面截图待补充

### 安全配置

- [x] 前端容器使用非 root Nginx 镜像运行
- [x] `.dockerignore` 已排除构建产物、缓存、IDE 文件、`.env` 等无关文件
- [x] 前端镜像集成 Trivy 漏洞扫描
- [x] 前端部署配置中未硬编码密码、Token 或 API Key

### 镜像优化

- [x] 使用多阶段构建
- [x] 使用 Alpine 变体的 Nginx 镜像
- [x] `.dockerignore` 排除无关文件，减少构建上下文体积
- [x] 前端生产镜像只包含构建后的 Web 静态资源和 Nginx 配置

## PR 链接

- PR #X: https://github.com/xi1xi1/Words/pull/X

## GitHub Actions / GHCR 证明

- GitHub Actions 链接：https://github.com/xi1xi1/Words/actions
- 前端镜像地址：`ghcr.io/xi1xi1/Words/frontend`


## 遇到的问题和解决

1. 问题：项目是 Flutter 前端，不能直接像普通静态项目一样复制源码运行。  
   解决：使用多阶段 Dockerfile，第一阶段执行 `flutter build web --release` 生成 `build/web`，第二阶段使用 Nginx 托管静态资源。

2. 问题：前端部署需要支持单页应用路由，否则刷新子路由可能出现 404。  
   解决：在 `frontend/nginx.conf` 中配置 `try_files $uri $uri/ /index.html;`，保证 Flutter Web 路由可以正常回退到 `index.html`。

3. 问题：PDF 要求容器具备健康检查。  
   解决：在 Nginx 中新增 `/health` 路径，并在 Dockerfile、Compose 中配置 healthcheck。

4. 问题：本人只负责前端，PDF 中后端 Dockerfile、数据库持久化、生产密钥管理等内容不属于本人职责。  
   解决：前端贡献说明中明确标注后端和数据库部分由后端/部署成员负责，本人仅完成前端容器化、Compose 前端服务和前端 GHCR 自动构建推送。

## AI 使用情况

- 使用了哪些 Prompt：
  - 阅读系统部署 PDF，提取前端需要完成的 Docker 部署任务。
  - 为 Flutter 前端生成多阶段 Dockerfile。
  - 为前端服务生成 Docker Compose 开发和生产配置。
  - 为前端镜像生成 GitHub Actions 自动构建、推送 GHCR 和 Trivy 扫描配置。

- AI 帮助解决了哪些问题：
  - 区分 PDF 中前端职责与后端/数据库职责。
  - 设计 Flutter Web 的 Docker 多阶段构建流程。
  - 配置 Nginx 支持 Flutter Web 单页应用路由。
  - 配置 GitHub Actions 将前端镜像推送到 GHCR。
  - 整理个人 Docker 部署贡献说明。

## 心得体会

通过本次 Docker 部署任务，我了解了 Flutter Web 前端项目从源码构建到容器运行的完整流程。相比普通前端项目，Flutter 前端需要先构建 Web 静态资源，再交给 Nginx 托管。通过多阶段构建，可以让最终镜像只保留运行所需文件，减少镜像体积；通过非 root 镜像、`.dockerignore` 和 Trivy 扫描，也能提升部署安全性。GitHub Actions 自动构建并推送 GHCR 镜像，使前端部署流程更加标准化，后续只需要推送代码即可触发镜像构建。
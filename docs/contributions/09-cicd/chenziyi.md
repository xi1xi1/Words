# CI/CD 配置贡献说明
姓名：陈子怡  学号：2312190329  角色：后端  日期：2026-04-29

## 完成的工作

### 工作流相关
- [x] 参与编写/审查 `.github/workflows/ci.yml`
- [x] 配置 Codecov 覆盖率上传（backend / frontend flag）
- [x] 添加 README 状态徽章

### 代码适配
- [x] 本地测试命令与 CI 一致（后端按 CI 参数执行 Maven 测试）
- [x] 代码通过 Lint 检查（后端 Checkstyle 通过）
- [x] 核心覆盖率达标（> 60%，JaCoCo check 已通过）

### 可选项
- [ ] 配置 Dependabot 自动更新依赖
- [ ] 集成 CodeRabbit AI 代码审查
- [x] 使用 act 本地验证工作流

## act 本地验证过程记录

- 环境准备：
  - 启动本地容器：`docker-compose up -d`
  - 安装 act：`winget install --id nektos.act -e`
  - 版本验证：`act version 0.2.87`
- 工作流识别：
  - 执行：`act -W .github/workflows/ci.yml -l`
  - 结果：可识别 `frontend`、`backend-lint`、`backend` 三个 job。
- 本地执行/预演：
  - 执行：`act -W .github/workflows/ci.yml -j backend-lint -P ubuntu-latest=catthehacker/ubuntu:act-latest`
  - 结果：job 成功进入 Set up job，并完成容器启动与 action 拉取阶段（本地镜像/网络阶段耗时较长）。
  - 执行：`act -W .github/workflows/ci.yml -j backend -n -P ubuntu-latest=catthehacker/ubuntu:act-latest`
  - 结果：在 Windows + Docker 下 dry-run 触发 act 对 service health 检查的已知异常（panic），因此后端 service 容器相关流程以 GitHub Actions 在线执行结果为准。

## PR 链接
- PR #54: https://github.com/xi1xi1/Words/pull/54

## CI 运行链接
- https://github.com/xi1xi1/Words/actions/workflows/ci.yml

## 遇到的问题和解决
1. 问题：PowerShell 下 Maven `-D` 参数中带特殊字符时被错误解析，导致插件解析异常。  
   解决：改用环境变量注入数据库参数，或使用更稳妥的命令写法。
2. 问题：JaCoCo 出现 execution data 不匹配/缺失。  
   解决：清理 `backend/target` 后执行 `clean test`，并在 Surefire 中显式继承 `argLine`，保证生成并读取 `jacoco.exec`。
3. 问题：act 在本机对含 service 的 backend job dry-run 出现 health 检查 panic。  
   解决：保留 act 本地验证记录（job 识别与基础预演），最终以 GitHub Actions 在线运行结果作为验收依据。

## 心得体会
本次 CI/CD 任务的关键是让“本地可复现”和“线上可通过”保持一致：明确测试命令、固定覆盖率门禁、把异常分支补测到位。通过 act 预演可以提前发现环境差异问题，但最终仍需以 GitHub Actions 作为统一验收口径。

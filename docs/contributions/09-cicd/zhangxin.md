# CI/CD 配置贡献说明

姓名：张欣  
学号：2312190333  
角色：前端  
日期：2026-04-29

## 完成的工作

### 工作流相关
- [x] 参与编写 / 审查 `.github/workflows/ci.yml`
- [x] 配置 Codecov 覆盖率上传（frontend flag）
- [x] 添加 README 状态徽章

### 代码适配
- [x] 本地测试命令与 CI 一致，无需额外配置
- [x] 代码通过 Lint 检查（Flutter analyze）
- [x] 核心覆盖率达标（84.61% > 60%）

### 可选项
- [x] 配置 Dependabot 自动更新依赖
- [x] 集成 CodeRabbit AI 代码审查
- [ ] 使用 act 本地验证工作流

## Dependabot 自动更新依赖

已新增 `.github/dependabot.yml`，配置每周一自动检查并提交依赖更新 PR：

- GitHub Actions 依赖：检查 `.github/workflows/` 中使用的 Actions 版本
- Flutter Pub 依赖：检查 `frontend/pubspec.yaml` / `pubspec.lock` 中的前端依赖

## CodeRabbit AI 代码审查

已在 CodeRabbit 中启用 `xi1xi1/Words` 仓库，集成 AI 代码审查能力：

- 授权范围：仅授权当前项目仓库
- 触发方式：创建或更新 Pull Request 时自动触发审查
- 审查内容：生成 PR Summary、Walkthrough、文件变更说明和 Review 建议
- 验证方式：通过 Pull Request 页面查看 CodeRabbit 自动生成的审查评论

## 前端 CI 命令

```bash
flutter pub get
flutter analyze
flutter test --coverage
```

## 覆盖率报告

- 报告文件：`frontend/coverage/lcov.info`
- Codecov flag：`frontend`
- 当前线覆盖率：84.61%

## PR 链接

- PR #43: https://github.com/xi1xi1/Words/pull/43

## CI 运行链接

- https://github.com/xi1xi1/Words/actions

## 遇到的问题和解决

1. 问题：项目是 Flutter，不适用示例中的 `npm test` / `ESLint` 命令。  
   解决：将前端 CI 命令替换为 `flutter pub get`、`flutter analyze`、`flutter test --coverage`。

2. 问题：Codecov 徽章最初显示 unknown。  
   解决：配置 `CODECOV_TOKEN`，并在 workflow 中上传 `frontend/coverage/lcov.info`，同时使用 `frontend` flag 区分前端覆盖率。

3. 问题：本地覆盖率与 CI 覆盖率需要保持一致。  
   解决：统一使用 `flutter test --coverage` 作为本地与 CI 的覆盖率生成命令。

## 心得体会

本次 CI/CD 配置让我理解了 GitHub Actions、Flutter 自动化检查、Codecov 覆盖率上传和 README 状态徽章之间的关系。通过把本地命令与 CI 命令保持一致，可以降低“本地通过但 CI 失败”的风险，也方便团队成员通过 PR 和 Actions 页面共同验证代码质量。

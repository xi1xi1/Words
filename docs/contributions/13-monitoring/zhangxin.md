# 监控配置贡献说明

姓名：张欣  
学号：2312190333  
角色：前端  
日期：2026-05-28  

## 分工说明

| 内容 | 负责人 |
|------|--------|
| 后端 JSON 日志、Micrometer 指标、Spring `/health` | 陈子怡 → [chenziyi.md](./chenziyi.md)、[monitoring.md](../../monitoring.md) |
| 前端 Nginx `/health`、Docker/Compose 探活、线上验证 | 张欣 |

---

## 我完成的工作

### 1. 日志配置

- [x] 减少探针噪声：在 `frontend/nginx.conf` 的 `location = /health` 配置 `access_log off`
- [x] 接口排障：通过浏览器 F12 → Network 查看 API 请求 URL、状态码与耗时

### 2. 健康检查

- [x] `/health` 端点实现（`frontend/nginx.conf`：`GET /health` → HTTP 200，正文 `healthy`）
- [x] 健康检查逻辑（Nginx 静态探活；`frontend/Dockerfile` 内 `HEALTHCHECK` 访问容器 `8080`）

**相关文件：**

- `frontend/nginx.conf`
- `frontend/Dockerfile`
- `compose.yaml`

**线上验证：**

| 项目 | URL | 预期 |
|------|-----|------|
| 前端健康检查 | https://words-production-371b.up.railway.app/health | 显示 `healthy` |
| 前端应用 | https://words-production-371b.up.railway.app | 可打开登录页，接口正常 |

### 3. 指标收集

- [x] 在联调中使用浏览器 Network 观察请求是否成功、响应时间是否正常

团队全站请求计数、P95 耗时、错误率等指标见 [monitoring.md](../../monitoring.md)。

---

## PR 链接

- 前端 Docker / Nginx 探活（第 11 周）：[11-docker/zhangxin.md](../11-docker/zhangxin.md)  
- 本次个人说明：`docs/contributions/13-monitoring/zhangxin.md`  
- 团队监控 PR：https://github.com/xi1xi1/Words/pull/90  

---

## 在线地址

| 说明 | 地址 |
|------|------|
| 前端应用 | https://words-production-371b.up.railway.app |
| 前端 `/health` | https://words-production-371b.up.railway.app/health |

---

## 学习通提交

1. **Git 提交记录：** `git log --author="张欣" --oneline --graph`  
2. **健康检查：** 浏览器打开 `https://words-production-371b.up.railway.app/health`，截图 `healthy`  
3. **结构化日志：** 附 `nginx.conf` 中 `access_log off` 配置截图，或 F12 Network 请求列表截图；全项目 JSON 日志说明见 [monitoring.md](../../monitoring.md)  

---

## 遇到的问题和解决

1. **问题：** Railway 上 Frontend 与 Backend 域名不同，访问 `/health` 时容易混淆。  
   **解决：** 前端探活使用 `words-production-371b.up.railway.app/health`，返回纯文本 `healthy`。

2. **问题：** 健康检查请求过多会产生大量 Nginx 访问日志。  
   **解决：** 在 `nginx.conf` 对 `/health` 关闭 access_log。

3. **问题：** 线上页面接口失败。  
   **解决：** 用 F12 Network 查看请求与 CORS；确认 `api_constants.dart` 中 `baseUrl` 为 HTTPS 线上后端地址。

---

## 心得体会

本次我主要完成前端容器的可观测性配置：用 Nginx `/health` 和 Dockerfile HEALTHCHECK 让 Railway 能判断 Flutter Web 静态服务是否存活，并通过关闭探针访问日志、浏览器 Network 联调等方式辅助排障。这与团队后端的 JSON 日志、业务健康检查和 Micrometer 指标形成互补，共同构成「背了么」的监控体系。

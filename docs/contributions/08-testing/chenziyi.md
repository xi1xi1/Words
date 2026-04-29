#  软件测试贡献说明
姓名：陈子怡    学号：2312190329    角色：后端     日期：2026-04-22

##  完成的测试工作

###  测试文件

#### 单元测试（Mockito Mock 隔离数据库/外部依赖）
-  `backend/src/test/java/com/zychen/backend/service/impl/StudyServiceImplTest.java`
-  `backend/src/test/java/com/zychen/backend/service/impl/AuthServiceImplTest.java`
-  `backend/src/test/java/com/zychen/backend/service/impl/ChallengeServiceImplTest.java`
-  `backend/src/test/java/com/zychen/backend/service/impl/AIServiceImplTest.java`
-  `backend/src/test/java/com/zychen/backend/config/JwtUtilTest.java`

#### API / 接口测试（MockMvc）
-  `backend/src/test/java/com/zychen/backend/controller/AuthControllerTest.java`
-  `backend/src/test/java/com/zychen/backend/controller/UserControllerTest.java`
-  `backend/src/test/java/com/zychen/backend/controller/WordControllerTest.java`
-  `backend/src/test/java/com/zychen/backend/controller/WordbookControllerTest.java`
-  `backend/src/test/java/com/zychen/backend/controller/ChallengeControllerTest.java`
-  `backend/src/test/java/com/zychen/backend/controller/LeaderboardControllerTest.java`
-  `backend/src/test/java/com/zychen/backend/controller/StudyControllerTest.java`

###  测试清单
-  [x]  正常情况测试（本项目测试总数：**117**，含单元测试与接口测试）
-  [x]  边界  /  异常情况测试（包含：未认证 401、参数缺失 400、资源不存在 404、题库不足、序列化失败、用户不存在等）
-  [x]  Mock  使用（数据库  /  API  /  组件外部依赖）
   - 单元测试使用 Mockito Mock mapper（隔离数据库）
   - `AIServiceImplTest` 使用 Spy 固定生成结果，避免真实外网 HTTP 调用，仅验证写库合并与 JSON 修复逻辑

###  覆盖率
-  GitHub（CI 展示）Overall Coverage：**60.95%**
-  IDEA（本地 Run with Coverage）Overall Coverage：**约 70%**
-  口径差异说明：
   - GitHub/CI 的统计通常更“严格”（例如包含更多模块/类、不同的排除规则、不同的测试执行入口与环境差异），因此整体覆盖率可能低于本地 IDE。
   - 本地 IDEA 覆盖率更偏向当前运行配置/选定范围的统计，数值可能更高。
-  覆盖率报告路径：`backend/htmlReport/index.html`


###  AI  辅助（如有）
-  使用工具：Cursor
-  Prompt  示例：
   - 为 `StudyServiceImpl` 编写 Mockito 单元测试，覆盖 getStats/getTrend/getCalendar 的正常/边界/异常分支，Mock 掉 mapper，不依赖数据库
   - 为 `AuthServiceImpl` 编写 Mockito 单元测试，覆盖注册/登录失败与成功分支，并验证密码哈希与 token 黑名单逻辑
   - 为 `ChallengeServiceImpl` 编写 Mockito 单元测试，覆盖题库不足、序列化失败、用户不存在、成功结算分支
   - 为 `JwtUtil` 编写单元测试，覆盖 token 生成解析与从 request 解析 userId 的分支
   - 为 `AIServiceImpl` 编写 Mockito 单元测试：不走真实 HTTP，通过 Spy 固定生成句子，覆盖写库合并例句与 JSON 规范化/修复分支，提高 `service.impl` 覆盖率
-  AI  生成  +  人工修改的测试数量：**117** 个（以当前测试总数为准）

##  PR  链接
-  PR  #45:  https://github.com/xi1xi1/Words/pull/45
-  PR  #46:  https://github.com/xi1xi1/Words/pull/46
-  PR  #47:  https://github.com/xi1xi1/Words/pull/47
##  遇到的问题和解决

-  **JaCoCo 报告未生成（missing execution data file）**：使用 IDEA 内置覆盖率工具（Run with Coverage）生成报告
-  **覆盖率口径不一致**：GitHub/CI 与本地 IDEA 的统计范围与排除规则不同，导致 GitHub 侧显示 60.95%，本地运行约 70%。统一以 GitHub/CI 为最终验收口径，同时保留本地覆盖率用于开发迭代参考。


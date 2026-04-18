# AI 功能说明

## 1. 功能概述

本项目在“背单词”主流程之外，增加了基于大语言模型的 AI 辅助学习能力，主要目标是让用户不仅能看到单词释义和例句，还能获得更适合记忆的联想内容，从而提升记忆效率和学习体验。

当前项目中的 AI 能力主要包含两部分：

1. **AI 联想记忆生成**
   - 针对指定单词生成中文记忆辅助内容
   - 返回结构化结果，便于前端分块展示

2. **AI 英文例句生成**
   - 在用户将单词加入生词本时，后端可异步生成英文例句
   - 生成结果会写回单词数据，供前端后续展示使用

也就是说，AI 功能不是一个独立页面，而是被嵌入到整个“单词详情—生词本—学习内容增强”的前后端协作链路中。

---

## 2. 使用的模型与接入方式

### 2.1 模型接入方式

本项目后端通过 **火山方舟 Ark 接口** 调用大语言模型能力。

后端代码中，AI 服务实现位于：
- `backend/src/main/java/com/zychen/backend/service/AIService.java`
- `backend/src/main/java/com/zychen/backend/service/impl/AIServiceImpl.java`

后端通过以下配置完成模型调用：
- `ark.base-url`
- `ark.api-key`
- `ark.endpoint-id`

其中：
- `ark.base-url`：Ark 模型服务地址
- `ark.api-key`：接口认证密钥
- `ark.endpoint-id`：实际调用的模型端点 ID

因此，本项目不是在前端直接接入某个模型 SDK，而是：

- **前端** 调用项目后端 API
- **后端** 统一封装 AI 能力
- **模型调用** 由后端通过 Ark 服务完成

### 2.2 当前架构特点

这种做法的优点是：
- 前端不暴露模型密钥，更安全
- 模型可以在后端统一切换，不影响前端代码
- AI 输出格式可以在后端统一规范，减轻前端解析压力
- 更适合课程项目中的前后端协同开发

---

## 3. 后端实现了什么 AI 功能

### 3.1 AI 联想记忆生成接口

后端控制器：
- `backend/src/main/java/com/zychen/backend/controller/WordbookController.java`

核心接口：
- `GET /api/wordbook/ai/{wordId}`

功能说明：
- 用户请求某个单词的 AI 联想记忆内容
- 后端根据 `wordId` 查询单词信息
- 提取单词本身及其释义
- 调用 AI 服务生成结构化联想记忆内容
- 返回给前端展示

### 3.2 AI 联想记忆服务逻辑

后端服务实现：
- `backend/src/main/java/com/zychen/backend/service/impl/WordbookServiceImpl.java`
- `backend/src/main/java/com/zychen/backend/service/impl/AIServiceImpl.java`

主要处理流程：
1. 根据 `wordId` 查询数据库中的单词
2. 校验单词是否存在
3. 从单词释义中优先提取第一个释义作为 AI 提示词输入
4. 调用 `aiService.generateMemoryContent(word, meaning)`
5. 将生成结果封装为 `AIMemoryContent`
6. 返回统一响应给前端

### 3.3 AI 英文例句生成

后端还实现了例句生成能力：
- `generateExample(String word, String meaning)`
- `generateAndPersistExample(Long wordId, String word, String meaning)`

功能说明：
- 当用户将单词加入生词本时，后端会触发例句生成逻辑
- AI 生成一句自然英文例句
- 后端将例句合并写入 `word.example` 字段
- 如果已有例句，会进行合并去重处理

这部分说明 AI 不只用于“展示联想记忆”，也用于“增强单词内容本身”。

### 3.4 AI 输出结构化约束

后端在调用模型时，通过 system prompt 明确要求模型返回严格 JSON，而不是自由文本。

当前联想记忆结果主要包括以下字段：
- `homophonic`：谐音联想
- `morpheme`：词根词缀联想
- `story`：场景故事联想
- `summary`：一句记牢总结
- `notes`：补充说明

后端对应 DTO：
- `backend/src/main/java/com/zychen/backend/dto/response/AIMemoryContent.java`
- `backend/src/main/java/com/zychen/backend/dto/response/MemoryHintBlock.java`

这样做的好处是：
- 返回结构稳定
- 前端更容易渲染
- 降低 AI 输出不可控导致的页面适配成本

---

## 4. 前端实现了什么 AI 功能

### 4.1 AI 功能入口

前端页面：
- `frontend/lib/features/home/screens/word_detail_screen.dart`

在单词详情页中，前端在“例句”卡片标题区域增加了：
- `生成联想记忆` 按钮

用户点击后，前端调用 AI 接口生成联想记忆内容。

### 4.2 AI 接口调用

前端服务层：
- `frontend/lib/services/wordbook_service.dart`

封装方法：
- `getAIMemoryContent(int wordId)`

该方法会请求：
- 后端 AI 接口 `/api/wordbook/ai/{wordId}`

并将返回结果解析为前端模型：
- `AIContentResponse`
- `MemoryHintBlock`

对应文件：
- `frontend/lib/models/wordbook_model.dart`

### 4.3 AI 内容展示

前端并不是直接展示一整段 AI 文本，而是按模块化方式展示：
- 记忆锚点
- 谐音联想
- 词根词缀联想
- 场景故事联想
- 一句记牢
- 补充说明

这种展示方式更符合英语学习场景，也更适合用户快速浏览和记忆。

### 4.4 交互反馈

前端还增加了完整的交互状态控制：
- 按钮 loading 状态
- 禁止重复点击
- 生成完成后显示“联想已生成”标签
- 空内容兼容处理
- 异常请求提示

这部分提升了 AI 功能的可用性和用户体验。

---

## 5. 前后端协作流程

整个 AI 功能的数据流如下：

1. 用户进入单词详情页
2. 前端展示单词释义与例句
3. 用户点击“生成联想记忆”
4. 前端调用 `/api/wordbook/ai/{wordId}`
5. 后端查询单词与释义
6. 后端通过 Ark 接口调用大语言模型
7. 模型返回结构化 JSON
8. 后端解析并封装为 `AIMemoryContent`
9. 前端接收数据并按模块展示
10. 用户查看联想记忆结果，辅助学习

此外，用户加入生词本时：
1. 前端调用加入生词本接口
2. 后端保存生词本状态
3. 后端异步触发 AI 英文例句生成
4. AI 例句写回单词数据
5. 后续前端获取单词详情时可展示更新后的例句内容

---

## 6. 当前已实现的 AI 功能点汇总

### 后端已实现
- [x] Ark 模型调用封装
- [x] AI 联想记忆生成
- [x] AI 英文例句生成
- [x] 严格 JSON 输出约束
- [x] AI 响应解析与 DTO 封装
- [x] 加入生词本后异步生成例句
- [x] AI 生成失败兜底处理

### 前端已实现
- [x] 单词详情页 AI 入口
- [x] AI 接口请求封装
- [x] AI 数据模型适配
- [x] AI 联想记忆卡片展示
- [x] loading 状态与防重复点击
- [x] AI 已生成状态提示
- [x] AI 空内容兼容展示

---

## 7. AI 返回内容结构

### 后端返回核心字段

- `word`：当前单词
- `meaning`：当前用于生成的释义/记忆锚点
- `homophonic`：谐音联想模块
- `morpheme`：词根词缀模块
- `story`：故事联想模块
- `summary`：一句记牢总结
- `notes`：补充说明

### 模块结构

`homophonic` / `morpheme` / `story` 采用统一结构：
- `title`：模块标题
- `content`：核心联想内容
- `explanation`：解释说明

这使前端可以使用统一组件进行动态渲染。

---

## 8. 设计价值

本项目的 AI 功能设计价值主要体现在以下几个方面：

### 8.1 提升单词记忆效率

相比只展示释义和例句，AI 联想记忆可以帮助用户从发音、词形、场景、总结等多个角度理解单词，降低记忆难度。

### 8.2 提升内容丰富度

后端可自动生成英文例句和联想记忆内容，使单词学习内容从静态数据扩展为动态生成内容。

### 8.3 前后端职责清晰

- 前端负责交互、展示和体验
- 后端负责数据查询、模型调用、结果封装
- 模型调用细节不暴露给前端，系统更清晰也更安全

### 8.4 便于后续扩展

当前架构下，后续可以继续扩展：
- 重新生成联想记忆
- 根据用户年级/词汇水平生成不同风格内容
- 支持 AI 生成中文例句、近义词辨析、记忆卡片
- 支持缓存 AI 结果，减少重复生成成本

---

## 9. 当前文档结论

综上，本项目的 AI 功能已经形成了较完整的前后端闭环：

- **后端** 已完成模型调用封装、AI 内容生成、结构化输出与异步例句写回
- **前端** 已完成 AI 入口接入、接口调用、数据模型解析与页面展示
- **整体上** 已实现“请求 AI → 生成内容 → 返回前端 → 展示辅助学习”的完整功能链路

这使 AI 功能不再是单一的展示点，而是已经成为项目中增强单词学习体验的重要组成部分。

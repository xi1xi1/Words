# AI 功能说明

## 1. 功能概览

本项目后端已集成 AI 能力，当前包含两类功能：

1. **AI 联想记忆生成（对外接口）**
   - 接口：`GET /api/wordbook/ai/{wordId}`
   - 作用：为指定单词生成结构化联想记忆内容（谐音/拆词/故事/总结）
2. **AI 英文例句生成（内部异步能力）**
   - 触发点：添加单词到生词本时异步生成并更新 `word.example`
   - 作用：补充单词例句，提升学习内容丰富度

---

## 2. 使用模型与配置

后端通过火山方舟兼容接口调用模型，配置项如下：

- `ark.base-url`：模型调用地址
- `ark.api-key`：访问密钥
- `ark.endpoint-id`：模型端点（代码中作为 `model` 传入）

说明：
- 代码不写死具体模型名称，**实际模型由 `ark.endpoint-id` 决定**。
- 若 `ark.api-key` 或 `ark.endpoint-id` 未配置，服务会记录告警并返回空结果。

---

## 3. API 说明（AI 联想记忆）

### 3.1 接口定义

- 方法：`GET`
- 路径：`/api/wordbook/ai/{wordId}`
- 鉴权：需要 JWT（`Authorization: Bearer <token>`）
- 路径参数：
  - `wordId`（Long）：单词 ID

### 3.2 成功返回结构

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "word": "ambition",
    "meaning": "野心；雄心",
    "homophonic": {
      "title": "谐音记忆",
      "content": "俺必胜",
      "explanation": "有雄心的人才会说“俺必胜”"
    },
    "morpheme": null,
    "story": {
      "title": "故事记忆",
      "content": "......",
      "explanation": "......"
    },
    "summary": "ambition = 俺必胜 = 有雄心",
    "notes": "拆词为辅助记忆"
  }
}
```

### 3.3 失败返回

- `404`：单词不存在
- `500`：AI 生成失败（例如模型调用失败或返回内容无法解析）

---

## 4. 后端实现结构

### 4.1 Controller

- `WordbookController#getAIContent`
  - 接收 `userId` 与 `wordId`
  - 调用 `wordbookService.getAIContent(...)`

### 4.2 Service 业务流程

- `WordbookServiceImpl#getAIContent`
  1. 根据 `wordId` 查询 `word` 表，找不到返回 404
  2. 解析 `word.meaning` JSON 数组，优先取第一个释义作为 AI 输入
  3. 调用 `AIService#generateMemoryContent(word, meaning)`
  4. 若返回为空，抛出 `BusinessException(500, "AI生成失败")`
  5. 返回 `AIMemoryContent`

### 4.3 AIService 实现

- `AIServiceImpl#generateMemoryContent`
  - 构造 system/user prompt
  - 通过 OkHttp 调用 Ark 接口
  - 从 `choices[0].message.content` 提取文本
  - 做容错清洗后解析为 `AIMemoryContent`

---

## 5. AI 输出容错与稳定性处理

为降低模型输出不稳定导致的 500，已实现以下策略：

1. **严格 Prompt 约束**
   - 要求仅返回一个 JSON 对象
   - 禁止 Markdown、禁止代码块、限制字段名

2. **输出规范化**
   - 去除 ```json 代码块包裹
   - 从混合文本中提取 `{...}` 主体

3. **常见 JSON 修复**
   - 自动修复 `,}`、`,]` 这类尾逗号问题

4. **降低截断概率**
   - `max_tokens` 从 `512` 提升到 `768`

5. **可观测性日志**
   - 记录模型调用失败、响应解析失败
   - 在业务层记录 `userId/wordId/word/meaningPreview`，便于排查问题单词

---

## 6. 数据结构（DTO）

- `AIMemoryContent`
  - `word`
  - `meaning`
  - `homophonic`（`MemoryHintBlock` 或 `null`）
  - `morpheme`（`MemoryHintBlock` 或 `null`）
  - `story`（`MemoryHintBlock` 或 `null`）
  - `summary`
  - `notes`

- `MemoryHintBlock`
  - `title`
  - `content`
  - `explanation`

---

## 7. 与作业要求对应关系

- **AI 功能实现代码**：已在后端 Controller / Service / DTO 实现
- **模型说明**：由 `ark.endpoint-id` 指定，使用 Ark 接口调用
- **实现功能**：已提供可调用的 AI 联想记忆接口，并补充容错与日志能力


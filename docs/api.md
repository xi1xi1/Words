#  背了么 - 后端 API 设计文档

---

# 一、接口设计规范

## 1.1 基础规范

- 接口风格：RESTful
- 数据格式：JSON
- 请求前缀：`/api`
- 字符编码：UTF-8
- 认证方式：JWT（除登录/注册外均需携带）

---

## 1.2 请求头格式

```http
Content-Type: application/json
Authorization: Bearer <token>
```

---

## 1.3 统一响应格式

```json
{
  "code": 200,
  "message": "success",
  "data": {}
}
```

### 状态码说明

| 状态码 | 含义 |
|--------|------|
| 200 | 成功 |
| 400 | 参数错误 |
| 401 | 未登录或Token失效 |
| 403 | 无权限 |
| 500 | 服务器错误 |

---

# 二、认证模块 API

---

## 2.1 用户注册

**POST** `/api/auth/register`

### 请求参数

```json
{
  "username": "test123",
  "password": "123456"
}
```

---

## 2.2 用户登录

**POST** `/api/auth/login`

### 请求参数

```json
{
  "username": "test123",
  "password": "123456"
}
```

### 响应示例

```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "token": "jwt_token",
    "username": "test123",
    "totalScore": 1000
  }
}
```

---

# 三、单词学习模块 API

---

## 3.1 获取单词列表

**GET** `/api/word/list`

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | int | 是 | 页码 |
| size | int | 是 | 每页数量 |

---

## 3.2 添加生词并生成AI例句

**POST** `/api/word/add`

### 请求参数

```json
{
  "wordId": 1
}
```

### 返回示例

```json
{
  "code": 200,
  "message": "添加成功",
  "data": {
    "example": "He abandoned the plan.",
    "dialogue": "A: Why abandon it? B: It was too risky."
  }
}
```

---

## 3.3 获取我的词本

**GET** `/api/word/my`

---

## 3.4 删除生词

**DELETE** `/api/word/{wordId}`

---

## 3.5 单词复习

**POST** `/api/word/review`

### 请求参数

```json
{
  "wordId": 1,
  "correct": true
}
```

---

# 四、闯关模块 API

---

## 4.1 开始闯关

**GET** `/api/battle/start`

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| levelType | int | 是 | 1初级 2中级 3高级 |

---

## 4.2 提交闯关结果

**POST** `/api/battle/submit`

```json
{
  "levelType": 1,
  "score": 80
}
```

---

## 4.3 获取关卡信息

**GET** `/api/battle/level-info`

---

## 4.4 获取闯关记录

**GET** `/api/battle/record`

---

# 五、排行榜模块 API

---

## 5.1 获取排行榜

**GET** `/api/rank/list`

---

## 5.2 获取我的排名

**GET** `/api/rank/me`

---

# 六、用户信息模块 API

---

## 6.1 获取个人信息

**GET** `/api/user/info`

---

## 6.2 修改密码

**PUT** `/api/user/password`

```json
{
  "oldPassword": "123456",
  "newPassword": "654321"
}
```

---

## 6.3 更新头像

**PUT** `/api/user/avatar`

（文件上传，使用 multipart/form-data）

---

## 6.4 获取学习统计

**GET** `/api/user/statistics`

返回示例：

```json
{
  "totalWords": 300,
  "todayStudy": 20,
  "totalScore": 1500,
  "battleCount": 25
}
```

---

# 七、AI模块 API

---

## 7.1 手动生成例句

**POST** `/api/ai/generate`

```json
{
  "word": "abandon"
}
```

返回：

```json
{
  "example": "He decided to abandon the mission.",
  "dialogue": "A: Why abandon it? B: It was too dangerous."
}
```

---

# 八、安全与校验说明

- 所有接口统一进行参数校验（@Valid）
- 使用 JWT 拦截器统一认证
- 密码采用加密存储（BCrypt）
- 统一异常处理（@ControllerAdvice）
- 防止重复提交与SQL注入

---

# 九、接口版本规划

当前版本：`v1`

未来升级方式：

```
/api/v2/xxx
```

通过版本号控制接口迭代，保证向后兼容。

---
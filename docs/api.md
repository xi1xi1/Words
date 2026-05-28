# 背了么 API 说明文档

## 一、基本信息

| 项目 | 说明 |
|------|------|
| 项目名称 | 背了么 |
| 版本 | v1.0.0 |
| 基础地址 | `http://localhost:8080/api` |
| 响应格式 | JSON |
| 字符编码 | UTF-8 |

---

## 二、认证方式

除登录注册外，所有接口需要在请求头中携带 Token：

```
Authorization: Bearer <your-jwt-token>
```

**示例：**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 三、统一响应格式

### 3.1 成功响应

```json
{
  "code": 200,
  "message": "success",
  "data": { ... }
}
```

### 3.2 错误响应

```json
{
  "code": 400,
  "message": "错误信息",
  "errors": [
    {
      "field": "username",
      "message": "用户名不能为空"
    }
  ]
}
```

### 3.3 状态码说明

| 状态码 | 说明 |
|--------|------|
| 200 | 成功 |
| 201 | 创建成功 |
| 400 | 参数错误 |
| 401 | 未认证（Token无效/过期） |
| 403 | 无权限 |
| 404 | 资源不存在 |
| 500 | 服务器内部错误 |

---

## 四、认证接口（Auth）

### 4.1 用户注册

**接口：** `POST /api/auth/register`

**权限：** 公开

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| username | string | 是 | 用户名，3-50位 |
| password | string | 是 | 密码 8–72 位，须同时包含字母与数字 |
| email | string | 是 | 邮箱 |

**请求示例：**
```json
{
  "username": "zhangsan",
  "password": "Testpass1",
  "email": "zhangsan@example.com"
}
```

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "userInfo": {
      "id": 1001,
      "username": "zhangsan",
      "avatar": null,
      "totalScore": 0,
      "level": 1
    }
  }
}
```

**错误响应：**
```json
{
  "code": 400,
  "message": "用户名已存在",
  "errors": null
}
```

---

### 4.2 用户登录

**接口：** `POST /api/auth/login`

**权限：** 公开

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| username | string | 是 | 用户名，3-50位 |
| password | string | 是 | 密码，至少6位 |

**请求示例：**
```json
{
  "username": "zhangsan",
  "password": "123456"
}
```

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "userInfo": {
      "id": 1001,
      "username": "zhangsan",
      "avatar": null,
      "totalScore": 1250,
      "level": 3
    }
  }
}
```

**错误响应：**
```json
{
  "code": 401,
  "message": "用户名或密码错误",
  "errors": null
}
```

---

### 4.3 退出登录

**接口：** `POST /api/auth/logout`

**权限：** 需认证

**请求头：**
```
Authorization: Bearer <token>
```

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": null
}
```

---

## 五、用户接口（User）

### 5.1 获取用户信息

**接口：** `GET /api/user/profile`

**权限：** 需认证

**请求头：**
```
Authorization: Bearer <token>
```

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 1001,
    "username": "zhangsan",
    "avatar": "https://cdn.beileme.com/avatars/1.jpg",
    "totalScore": 1250,
    "level": 3
  }
}
```

---

### 5.2 更新用户信息

**接口：** `PUT /api/user/profile`

**权限：** 需认证

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| avatar | string | 否 | 头像URL |

**请求示例：**
```json
{
  "avatar": "https://cdn.beileme.com/avatars/new-avatar.png"
}
```

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": null
}
```

---

### 5.3 修改密码

**接口：** `PUT /api/user/password`

**权限：** 需认证

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| oldPassword | string | 是 | 原密码 |
| newPassword | string | 是 | 新密码，至少6位 |

**请求示例：**
```json
{
  "oldPassword": "123456",
  "newPassword": "654321"
}
```

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": null
}
```

---

## 六、单词接口（Words）

### 6.1 获取今日单词

**接口：** `GET /api/words/daily`

**权限：** 需认证

**请求头：**
```
Authorization: Bearer <token>
```

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "newWords": [
      {
        "id": 1,
        "word": "abandon",
        "meaning": ["v. 放弃", "n. 放任"],
        "phonetic": "/əˈbændən/",
        "example": ["He abandoned his plan.", "They abandoned the city."]
      }
    ],
    "reviewWords": [
      {
        "id": 10,
        "word": "serendipity",
        "meaning": ["n. 意外发现美好事物的能力"],
        "phonetic": "/ˌserənˈdɪpəti/",
        "example": ["Finding this job was pure serendipity."]
      }
    ]
  }
}
```

---

### 6.2 提交学习结果

**接口：** `POST /api/words/learn`

**权限：** 需认证

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| wordId | long | 是 | 单词ID |
| isCorrect | boolean | 是 | 是否正确 |

**请求示例：**
```json
{
  "wordId": 1,
  "isCorrect": true
}
```

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": null
}
```

---

### 6.3 搜索单词

**接口：** `GET /api/words/search`

**权限：** 需认证

**请求参数（Query）：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| keyword | string | 是 | 搜索关键词 |
| page | int | 否 | 页码，默认1 |
| size | int | 否 | 每页数量，默认20 |

**请求示例：**
```
GET /api/words/search?keyword=abandon&page=1&size=10
```

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "content": [
      {
        "id": 1,
        "word": "abandon",
        "meaning": ["v. 放弃", "n. 放任"],
        "phonetic": "/əˈbændən/",
        "example": ["He abandoned his plan."]
      }
    ],
    "total": 1,
    "page": 1,
    "size": 10
  }
}
```

---

### 6.4 获取单词详情

**接口：** `GET /api/words/{id}`

**权限：** 需认证

**路径参数：**

| 参数 | 类型 | 说明 |
|------|------|------|
| id | long | 单词ID |

**请求示例：**
```
GET /api/words/1
```

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 1,
    "word": "abandon",
    "meaning": ["v. 放弃", "n. 放任"],
    "phonetic": "/əˈbændən/",
    "example": ["He abandoned his plan.", "They abandoned the city."]
  }
}
```

**错误响应：**
```json
{
  "code": 404,
  "message": "单词不存在",
  "data": null
}
```

---

## 七、闯关接口（Challenge）

### 7.1 开始闯关

**接口：** `POST /api/challenge/start`

**权限：** 需认证

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| levelType | int | 是 | 1-初级场 2-中级场 3-高级场 |

**请求示例：**
```json
{
  "levelType": 1
}
```

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "challengeId": "ch_1701234567890",
    "questions": [
      {
        "id": 1,
        "word": "abandon",
        "options": ["放弃", "保留", "继续", "开始"],
        "correctIndex": 0
      },
      {
        "id": 2,
        "word": "ability",
        "options": ["能力", "弱点", "优势", "机会"],
        "correctIndex": 0
      }
    ],
    "timeLimit": 60
  }
}
```

---

### 7.2 提交闯关结果

**接口：** `POST /api/challenge/submit`

**权限：** 需认证

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| challengeId | string | 是 | 闯关ID |
| answers | array | 是 | 答题列表 |

**answers 结构：**

| 参数 | 类型 | 说明 |
|------|------|------|
| questionId | long | 题目ID |
| selectedIndex | int | 选择的选项索引 |
| timeSpent | int | 答题耗时（秒） |

**请求示例：**
```json
{
  "challengeId": "ch_1701234567890",
  "answers": [
    {
      "questionId": 1,
      "selectedIndex": 0,
      "timeSpent": 8
    },
    {
      "questionId": 2,
      "selectedIndex": 0,
      "timeSpent": 12
    }
  ]
}
```

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "score": 850,
    "correctCount": 2,
    "totalCount": 2,
    "accuracy": 1.0,
    "addedScore": 85,
    "totalScore": 1335
  }
}
```

---

### 7.3 获取闯关记录

**接口：** `GET /api/challenge/records`

**权限：** 需认证

**请求参数（Query）：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| levelType | int | 否 | 1-初级 2-中级 3-高级 |
| page | int | 否 | 页码，默认1 |
| size | int | 否 | 每页数量，默认20 |

**请求示例：**
```
GET /api/challenge/records?levelType=1&page=1&size=10
```

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "content": [
      {
        "id": 5001,
        "levelType": 1,
        "score": 850,
        "correctCount": 18,
        "totalCount": 20,
        "duration": 375,
        "createTime": "2026-03-18 15:30:00"
      }
    ],
    "total": 8,
    "page": 1,
    "size": 10
  }
}
```

---

## 八、排行榜接口（Leaderboard）

### 8.1 获取排行榜

**接口：** `GET /api/leaderboard`

**权限：** 需认证

**请求参数（Query）：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| type | string | 否 | total-总榜 daily-今日榜 weekly-周榜，默认total |
| limit | int | 否 | 返回数量，默认50，最大100 |

**请求示例：**
```
GET /api/leaderboard?type=total&limit=50
```

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "list": [
      {
        "rank": 1,
        "userId": 1001,
        "username": "单词达人",
        "avatar": null,
        "totalScore": 95580
      },
      {
        "rank": 2,
        "userId": 1002,
        "username": "学霸小王",
        "avatar": null,
        "totalScore": 92245
      }
    ],
    "myRank": 128
  }
}
```

---

## 九、生词本接口（Wordbook）

### 9.1 获取生词本列表

**接口：** `GET /api/wordbook/list`

**权限：** 需认证

**请求参数（Query）：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | int | 否 | 页码，默认1 |
| size | int | 否 | 每页数量，默认20 |

**请求示例：**
```
GET /api/wordbook/list?page=1&size=20
```

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "content": [
      {
        "id": 10001,
        "wordId": 1,
        "word": "abandon",
        "meaning": ["v. 放弃", "n. 放任"],
        "phonetic": "/əˈbændən/",
        "addTime": "2026-03-18 10:30:00"
      }
    ],
    "total": 128,
    "page": 1,
    "size": 20
  }
}
```

---

### 9.2 添加单词到生词本

**接口：** `POST /api/wordbook/add`

**权限：** 需认证

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| wordId | long | 是 | 单词ID |

**请求示例：**
```json
{
  "wordId": 1
}
```

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": null
}
```

---

### 9.3 从生词本移除

**接口：** `DELETE /api/wordbook/remove/{wordId}`

**权限：** 需认证

**路径参数：**

| 参数 | 类型 | 说明 |
|------|------|------|
| wordId | long | 单词ID |

**请求示例：**
```
DELETE /api/wordbook/remove/1
```

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": null
}
```

---

### 9.4 获取AI生成内容

**接口：** `GET /api/wordbook/ai/{wordId}`

**权限：** 需认证

**路径参数：**

| 参数 | 类型 | 说明 |
|------|------|------|
| wordId | long | 单词ID |

**请求示例：**
```
GET /api/wordbook/ai/1
```

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "word": "abandon",
    "examples": [
      "He abandoned his plan.",
      "They abandoned the city."
    ],
    "dialogues": [
      {
        "scene": "告别场景",
        "conversation": [
          "A: Why did you leave?",
          "B: I had to abandon the project."
        ]
      }
    ]
  }
}
```

---

## 十、学习统计接口（Study）

### 10.1 获取学习统计

**接口：** `GET /api/study/stats`

**权限：** 需认证

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "todayStudy": 35,
    "todayReview": 80,
    "totalWords": 1245,
    "masteredWords": 876,
    "wordbookWords": 128,
    "dueReviewCount": 45,
    "totalScore": 1250,
    "level": 3
  }
}
```

---

### 10.2 获取学习趋势

**接口：** `GET /api/study/trend`

**权限：** 需认证

**请求参数（Query）：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| days | int | 否 | 天数，默认7 |

**请求示例：**
```
GET /api/study/trend?days=7
```

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "date": "2026-03-19",
      "studyCount": 30,
      "reviewCount": 45,
      "correctRate": 0.85
    },
    {
      "date": "2026-03-20",
      "studyCount": 35,
      "reviewCount": 80,
      "correctRate": 0.78
    }
  ]
}
```

---

### 10.3 获取学习日历

**接口：** `GET /api/study/calendar`

**权限：** 需认证

**请求参数（Query）：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| year | int | 是 | 年份 |
| month | int | 是 | 月份（1-12） |

**请求示例：**
```
GET /api/study/calendar?year=2026&month=3
```

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "date": "2026-03-01",
      "count": 45,
      "level": 2
    },
    {
      "date": "2026-03-02",
      "count": 30,
      "level": 1
    }
  ]
}
```

---

## 十一、错误码说明

| 错误码 | 说明 |
|--------|------|
| 1001 | Token无效，请重新登录 |
| 1002 | Token过期，请刷新Token或重新登录 |
| 1003 | 账号不存在 |
| 1004 | 密码错误 |
| 1005 | 用户名已存在 |
| 2001 | 单词不存在 |
| 2002 | 单词已在生词本 |
| 2003 | 生词本已满 |
| 3001 | 闯关不存在 |
| 3002 | 闯关已结束 |
| 4001 | 参数校验失败 |
| 5001 | 服务器繁忙，请稍后重试 |

---

## 十二、Flutter 调用示例

### 12.1 封装 HTTP 客户端

```dart
// lib/services/api_client.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:8080/api';
  
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  Future<Map<String, dynamic>> get(String path) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.get(url, headers: await _getHeaders());
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.put(
      url,
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> delete(String path) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.delete(url, headers: await _getHeaders());
    return _handleResponse(response);
  }
  
  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300 && data['code'] == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? '请求失败');
    }
  }
}
```

### 12.2 登录调用示例

```dart
// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _apiClient.post('/auth/login', {
        'username': username,
        'password': password,
      });
      
      final token = response['data']['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      
      return response['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> register(String username, String password, String email) async {
    try {
      final response = await _apiClient.post('/auth/register', {
        'username': username,
        'password': password,
        'email': email,
      });
      
      final token = response['data']['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      
      return response['data'];
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout', {});
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
    }
  }
}
```

### 12.3 获取用户信息示例

```dart
// lib/services/user_service.dart
import 'api_client.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();
  
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiClient.get('/user/profile');
    return response['data'];
  }
  
  Future<void> updateAvatar(String avatarUrl) async {
    await _apiClient.put('/user/profile', {'avatar': avatarUrl});
  }
  
  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _apiClient.put('/user/password', {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }
}
```

---

**文档版本：** v1.0.0  
**最后更新：** 2026-03-25
```


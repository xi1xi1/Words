# 背了么 —— API 设计文档

## 一、API 设计规范
### 1.1 通用规范
RESTful 风格：资源通过URL定位，用HTTP方法表示操作  
请求前缀：所有接口以 /api 开头  
认证方式：JWT Token，放在 Authorization: Bearer <token> 头中  
请求格式：application/json  
响应格式：统一JSON结构  

### 1.2 统一返回格式
```json  
{  
  "code": 200,  
  "message": "success",  
  "data": {}  
}  
```
### 1.3 状态码说明
状态码	说明   
200	成功  
400	参数错误  
401	未认证（Token无效/过期） 
403	无权限  
404	资源不存在  
500	服务器内部错误  
### 1.4 分页请求格式
```json
{
  "page": 1,
  "size": 20,
  "sort": "create_time desc"
}
```
### 1.5 分页响应格式
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "content": [],
    "total": 100,
    "page": 1,
    "size": 20
  }
}
```
## 二、认证模块（Auth）
### 2.1 用户注册
接口：POST /api/auth/register  
权限：公开  
描述：新用户注册  
### 请求参数
```json
{
  "username": "zhangsan",
  "password": "123456",
  "email": "zhangsan@example.com"
}
```
### 响应成功
```json
{
  "code": 200,
  "message": "注册成功",
  "data": {
    "userId": 1001,
    "token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```
### 错误示例
```json
{
  "code": 400,
  "message": "用户名已存在",
  "data": null
}
```
### 2.2 用户登录
接口：POST /api/auth/login  
权限：公开  
描述：用户登录，返回Token  
### 请求参数
```json
{
  "username": "zhangsan",
  "password": "123456"
}
```
### 响应成功
```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
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
### 2.3 退出登录
接口：POST /api/auth/logout  
权限：需认证  
描述：退出登录（客户端删除Token即可，服务端可选黑名单） 
### 响应成功
```json
{
  "code": 200,
  "message": "退出成功",
  "data": null
}
```
### 2.4 刷新Token
接口：POST /api/auth/refresh  
权限：需认证  
描述：用旧Token换取新Token  
### 响应成功
```json
{
  "code": 200,
  "message": "刷新成功",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```
## 三、用户模块（User）
### 3.1 获取用户信息
接口：GET /api/user/profile  
权限：需认证  
描述：获取当前登录用户的详细信息  
### 响应成功
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 1001,
    "username": "zhangsan",
    "avatar": "https://example.com/avatar.png",
    "totalScore": 1250,
    "level": 3,
    "createTime": "2026-01-15 10:30:00"
  }
}
```
### 3.2 更新用户信息
接口：PUT /api/user/profile  
权限：需认证  
描述：更新用户头像等信息  
### 请求参数
```json
{
  "avatar": "https://example.com/new-avatar.png"
}
```
### 响应成功
```json
{
  "code": 200,
  "message": "更新成功",
  "data": null
}
```
### 3.3 修改密码
接口：POST /api/user/change-password  
权限：需认证  
描述：修改登录密码  
### 请求参数

```json
{
  "oldPassword": "123456",
  "newPassword": "654321"
}
```
### 响应成功

```json
{
  "code": 200,
  "message": "密码修改成功",
  "data": null
}
```
## 四、单词模块（Word）
### 4.1 获取今日学习单词
接口：GET /api/words/daily  
权限：需认证  
描述：获取今日需要学习的单词列表（默认5个）  
### 响应成功
```json
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "id": 1,
      "word": "abandon",
      "meaning": ["v. 放弃", "n. 放任"],
      "phonetic": "/əˈbændən/",
      "example": ["He abandoned his plan.", "They abandoned the city."]
    },
    {
      "id": 2,
      "word": "ability",
      "meaning": ["n. 能力", "才能"],
      "phonetic": "/əˈbɪləti/",
      "example": ["She has the ability to learn fast."]
    }
  ]
}
```
### 4.2 提交学习记录
接口：POST /api/words/learn  
权限：需认证  
描述：提交单词学习结果，更新复习计划  
### 请求参数
```json
{
  "wordId": 1,
  "isCorrect": true
}
```
### 响应成功
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "nextWord": {
      "id": 2,
      "word": "ability",
      "meaning": ["n. 能力", "才能"],
      "phonetic": "/əˈbɪləti/"
    },
    "progress": {
      "learned": 1,
      "total": 5,
      "percentage": 20
    }
  }
}
```
### 4.3 获取复习单词列表
接口：GET /api/words/review  
权限：需认证  
描述：获取今日需要复习的单词列表（按复习时间排序） 
### 响应成功
```json
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "id": 10,
      "word": "serendipity",
      "meaning": ["n. 意外发现美好事物的能力"],
      "phonetic": "/ˌserənˈdɪpəti/",
      "reviewCount": 2,
      "memoryScore": 0.65
    }
  ]
}
```
### 4.4 单词详情
接口：GET /api/words/{wordId}  
权限：需认证  
描述：获取单个单词的详细信息  
### 响应成功
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 1,
    "word": "abandon",
    "meaning": ["v. 放弃", "n. 放任"],
    "phonetic": "/əˈbændən/",
    "example": ["He abandoned his plan.", "They abandoned the city."],
    "partOfSpeech": ["verb", "noun"],
    "synonyms": ["desert", "leave"],
    "antonyms": ["keep", "maintain"]
  }
}
```
## 五、生词本模块（Wordbook）
### 5.1 加入生词本
接口：POST /api/wordbook/add  
权限：需认证  
描述：将单词加入生词本（设置status=2） 
### 请求参数
```json
{
  "wordId": 1
}
```
### 响应成功
```json
{
  "code": 200,
  "message": "已加入生词本",
  "data": {
    "wordbookId": 10001
  }
}
```
### 5.2 从生词本移除
接口：DELETE /api/wordbook/remove/{wordId}  
权限：需认证  
描述：将单词从生词本移除  
### 响应成功
```json
{
  "code": 200,
  "message": "已移除",
  "data": null
}
```
### 5.3 获取生词本列表
接口：GET /api/wordbook/list  
权限：需认证  
描述：分页获取生词本中的单词  
### 请求参数（Query）
```
?page=1&size=20&sort=create_time desc
```
### 响应成功
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
### 5.4 获取AI例句
接口：GET /api/wordbook/ai/{wordId}  
权限：需认证  
描述：获取AI生成的单词例句和对话  
### 响应成功
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "word": "serendipity",
    "examples": [
      "Finding this job was pure serendipity.",
      "The discovery was a serendipity that changed science."
    ],
    "dialogues": [
      {
        "scene": "咖啡馆相遇",
        "conversation": [
          "A: I can't believe we both ordered the same coffee!",
          "B: What a serendipity! We must be soulmates."
        ]
      }
    ]
  }
}
```
## 六、闯关模块（Challenge）
### 6.1 开始闯关
接口：POST /api/challenge/start  
权限：需认证  
描述：开始一局闯关，返回题目列表  
### 请求参数
```json
{
  "level": 1
  // 1-初级 2-中级 3-高级
}
```
### 响应成功
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "challengeId": 5001,
    "level": 1,
    "timeLimit": 60,
    "questions": [
      {
        "id": 1,
        "word": "abundant",
        "options": ["丰富的", "缺乏的", "普通的", "罕见的"],
        "correctIndex": 0
      },
      {
        "id": 2,
        "word": "ubiquitous",
        "options": ["短暂的", "无处不在的", "雄辩的", "有弹性的"],
        "correctIndex": 1
      }
    ],
    "totalCount": 5
  }
}
```
### 6.2 提交答案（实时）
接口：POST /api/challenge/submit-answer  
权限：需认证  
描述：实时提交单题答案（可选，也可最后一起提交） 
### 请求参数
```json
{
  "challengeId": 5001,
  "questionId": 1,
  "selectedIndex": 0,
  "timeSpent": 8
}
```
### 响应成功
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "isCorrect": true,
    "currentScore": 100,
    "nextQuestion": {
      "id": 2,
      "word": "ubiquitous",
      "options": ["短暂的", "无处不在的", "雄辩的", "有弹性的"]
    }
  }
}
```
### 6.3 提交闯关结果
接口：POST /api/challenge/submit  
权限：需认证  
描述：提交整局闯关结果  
### 请求参数
```json
{
  "challengeId": 5001,
  "answers": [
    {
      "questionId": 1,
      "selectedIndex": 0,
      "isCorrect": true,
      "timeSpent": 8
    },
    {
      "questionId": 2,
      "selectedIndex": 1,
      "isCorrect": true,
      "timeSpent": 12
    }
  ],
  "totalTime": 45
}
```
### 响应成功
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "score": 850,
    "correctCount": 4,
    "totalCount": 5,
    "correctRate": 0.8,
    "scoreChange": "+85",
    "rewards": {
      "exp": 50,
      "coins": 100
    }
  }
}
```
## 七、排行榜模块（Leaderboard）
### 7.1 获取排行榜
接口：GET /api/leaderboard  
权限：需认证  
描述：获取排行榜数据  
请求参数（Query）
```
?type=daily  // daily-今日榜 weekly-周榜 total-总榜
&page=1
&size=20
```
### 响应成功
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "type": "total",
    "myRank": {
      "ranking": 128,
      "username": "zhangsan",
      "totalScore": 1250,
      "avatar": null
    },
    "list": [
      {
        "ranking": 1,
        "username": "单词达人",
        "totalScore": 95580,
        "avatar": null,
        "trend": "up"  // up-上升 down-下降 new-新上榜
      },
      {
        "ranking": 2,
        "username": "学霸小王",
        "totalScore": 92245,
        "avatar": null,
        "trend": "down"
      },
      {
        "ranking": 3,
        "username": "英语大神",
        "totalScore": 89930,
        "avatar": null,
        "trend": "up"
      }
    ],
    "total": 1000,
    "page": 1,
    "size": 20
  }
}
```
## 八、数据统计模块（Stats）
### 8.1 获取用户学习统计
接口：GET /api/stats/overview  
权限：需认证  
描述：获取用户学习数据概览  
### 响应成功
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "today": {
      "studyCount": 35,
      "reviewCount": 80,
      "totalTime": 42
    },
    "total": {
      "studyCount": 1245,
      "masteredCount": 876,
      "totalTime": 5680
    },
    "wordbookCount": 128,
    "battleStats": {
      "totalGames": 8,
      "avgScore": 72,
      "highestScore": 90,
      "correctRate": 0.67
    }
  }
}
```
### 8.2 获取学习趋势
接口：GET /api/stats/trend  
权限：需认证  
描述：获取近7天学习趋势  
### 请求参数（Query）
```
?days=7
```
### 响应成功
```json
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "date": "2026-03-12",
      "studyCount": 30,
      "reviewCount": 45,
      "correctRate": 0.85
    },
    {
      "date": "2026-03-13",
      "studyCount": 25,
      "reviewCount": 50,
      "correctRate": 0.82
    },
    {
      "date": "2026-03-14",
      "studyCount": 35,
      "reviewCount": 80,
      "correctRate": 0.78
    }
  ]
}
```
### 8.3 获取学习日历
接口：GET /api/stats/calendar  
权限：需认证  
描述：获取指定月份的学习日历热力图数据  
### 请求参数（Query）
```
?year=2026&month=3
```
### 响应成功
```json
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "date": "2026-03-01",
      "count": 45,
      "level": 2  // 0-无 1-少 2-中 3-多
    },
    {
      "date": "2026-03-02",
      "count": 30,
      "level": 1
    }
  ]
}
```
## 九、闯关记录模块（Battle History）
### 9.1 获取闯关记录列表
接口：GET /api/battle/history  
权限：需认证  
描述：分页获取用户的闯关历史记录  
### 请求参数（Query）
```
?page=1&size=10
```
### 响应成功
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "content": [
      {
        "id": 5001,
        "levelType": 2,
        "levelName": "中级场",
        "score": 850,
        "correctCount": 18,
        "totalCount": 25,
        "correctRate": 0.72,
        "createTime": "2026-03-18 15:30:00",
        "duration": 510,
        "words": ["serendipity", "ephemeral", "ubiquitous"]
      },
      {
        "id": 5000,
        "levelType": 1,
        "levelName": "初级场",
        "score": 720,
        "correctCount": 17,
        "totalCount": 20,
        "correctRate": 0.85,
        "createTime": "2026-03-18 10:20:00",
        "duration": 375,
        "words": ["abandon", "ability", "absent"]
      }
    ],
    "total": 8,
    "page": 1,
    "size": 10,
    "summary": {
      "totalGames": 8,
      "avgScore": 72,
      "highestScore": 90,
      "avgCorrectRate": 0.67
    }
  }
}
```
### 9.2 获取闯关详情
接口：GET /api/battle/detail/{recordId}  
权限：需认证  
描述：获取单次闯关的详细答题数据  
### 响应成功
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 5001,
    "levelType": 2,
    "levelName": "中级场",
    "score": 850,
    "correctCount": 18,
    "totalCount": 25,
    "createTime": "2026-03-18 15:30:00",
    "duration": 510,
    "details": [
      {
        "questionId": 1,
        "word": "serendipity",
        "selectedIndex": 0,
        "isCorrect": true,
        "timeSpent": 8
      },
      {
        "questionId": 2,
        "word": "ephemeral",
        "selectedIndex": 1,
        "isCorrect": true,
        "timeSpent": 12
      }
    ]
  }
}
```
### 9.3 获取成就墙
接口：GET /api/battle/achievements  
权限：需认证  
描述：获取用户获得的成就 
### 响应成功
```json
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "id": 1,
      "name": "初出茅庐",
      "description": "完成第一次闯关",
      "icon": "🏆",
      "achievedAt": "2026-03-10",
      "progress": 1,
      "total": 1
    },
    {
      "id": 2,
      "name": "中级挑战者",
      "description": "在中级场获得80%以上正确率",
      "icon": "⭐",
      "achievedAt": "2026-03-15",
      "progress": 1,
      "total": 1
    },
    {
      "id": 3,
      "name": "单词达人",
      "description": "累计学习1000个单词",
      "icon": "📚",
      "progress": 876,
      "total": 1000
    }
  ]
}
```
## 十、错误码说明
***1001***：Token无效 - 重新登录  
***1002***：Token过期 - 刷新Token或重新登录  
***1003***：账号不存在 - 检查用户名  
***1004***：密码错误 - 重新输入  
***1005***：用户名已存在 - 更换用户名  
***2001***：单词不存在 - 检查wordId  
***2002***：单词已在生词本 - 无需重复添加  
***2003***：生词本已满 - 清理后重试  
***3001***：闯关不存在 - 检查challengeId  
***3002***：闯关已结束 - 开始新闯关  
***4001***：参数校验失败 - 检查请求参数  
***5001***：服务器繁忙 - 稍后重试  
## 十一、API 调用示例（Flutter）
### 11.1 封装请求客户端
```dart
class ApiClient {
  static const String baseUrl = 'http://localhost:8080/api';
  String? _token;
  
  Future<Map<String, String>> _getHeaders() async {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }
  
  Future<T> get<T>(String path, T Function(Map<String, dynamic>) fromJson) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.get(url, headers: await _getHeaders());
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['code'] == 200) {
        return fromJson(json['data']);
      } else {
        throw Exception(json['message']);
      }
    }
    throw Exception('请求失败: ${response.statusCode}');
  }
  
  // post, put, delete 类似...
}
```
### 11.2 登录调用示例
```dart
Future<void> login(String username, String password) async {
  try {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['code'] == 200) {
        final token = result['data']['token'];
        // 保存token到SharedPreferences
        await prefs.setString('token', token);
      } else {
        // 显示错误
        showError(result['message']);
      }
    }
  } catch (e) {
    showError('网络错误');
  }
}
```

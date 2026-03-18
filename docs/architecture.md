# 背了么 App - 软件架构设计文档

## 一、系统架构概览

背了么 App 采用 **前后端分离架构**，前端为 Flutter 跨平台应用，后端为 Spring Boot 微服务架构，数据层使用 MySQL 数据库。

### 架构图（Mermaid）

```mermaid
graph TB
    subgraph "客户端层"
        A1[Android App]
    end
    
    subgraph "前端层 Flutter"
        B1[UI组件层]
        B2[状态管理 Provider]
        B3[服务层 API调用]
        B4[本地存储 SharedPreferences]
    end
    
    subgraph "接入层"
        C1[Nginx 负载均衡]
        C2[静态资源 CDN]
    end
    
    subgraph "后端层 Spring Boot"
        D1[Controller 层]
        D2[Service 层]
        D3[Mapper 层 MyBatis]
        D4[安全认证 JWT]
        D5[全局异常处理]
    end
    
    subgraph "数据层"
        E1[(MySQL 主库)]
        E2[(MySQL 从库)]
        E3[Redis 缓存]
    end
    
    A1 --> B1
    B1 --> B2
    B2 --> B3
    B3 --> C1
    C1 --> D1
    D1 --> D2
    D2 --> D3
    D3 --> E1
    D3 --> E2
    D2 --> E3
    
    style A1 fill:#f9f,stroke:#333
    style B1 fill:#bbf,stroke:#333
    style D1 fill:#bfb,stroke:#333
    style E1 fill:#fbb,stroke:#333
```

### 系统分层说明

**客户端层**：Android - 用户设备端运行环境  
**前端层**：Flutter + Dart - UI渲染、用户交互、状态管理  
**接入层**：Nginx - 反向代理、负载均衡、静态资源服务  
**后端层**：Spring Boot + Java 17 - 业务逻辑处理、API接口提供  
**数据层**：MySQL + Redis - 数据持久化、缓存加速

## 二、前端架构设计
### 2.1 前端整体架构（Mermaid）
```mermaid
graph TB
    subgraph "Flutter 前端架构"
        direction TB
        View[视图层<br/>Widgets/Screens]
        State[状态管理层<br/>Provider]
        Service[服务层<br/>HTTP请求]
        Model[数据模型层<br/>Entities]
        Local[本地存储层<br/>SharedPreferences]
        
        View --> State
        State --> Service
        Service --> Model
        State --> Local
    end
    
    View --> UI[用户界面]
    Service --> API[后端API]
    
    style View fill:#e1f5fe
    style State fill:#fff9c4
    style Service fill:#dcedc8
```
### 2.2 页面/组件结构（Mermaid）
```mermaid
graph LR
    subgraph "路由入口"
        App[App.dart]
    end
    
    subgraph "底部导航"
        TabBar[底部导航栏]
    end
    
    subgraph "核心页面"
        Home[首页]
        Challenge[闯关页]
        Profile[我的页]
    end
    
    subgraph "子页面"
        Study[学习页]
        Review[复习页]
        WordDetail[单词详情]
        Leaderboard[排行榜]
        Battle[对战页]
        Wordbook[生词本]
        Settings[设置页]
    end
    
    subgraph "公共组件"
        WordCard[单词卡片]
        ProgressBar[进度条]
        Loading[加载动画]
        Toast[提示组件]
    end
    
    App --> TabBar
    TabBar --> Home
    TabBar --> Challenge
    TabBar --> Profile
    
    Home --> Study
    Home --> Review
    Home --> WordDetail
    
    Challenge --> Leaderboard
    Challenge --> Battle
    
    Profile --> Wordbook
    Profile --> Settings
    
    Home --> WordCard
    Challenge --> WordCard
    WordDetail --> WordCard
    Study --> ProgressBar
    Review --> ProgressBar
```
### 2.3 前端模块划分

**auth**：登录注册、Token管理 - LoginScreen, RegisterScreen  
**home**：首页概览、学习入口 - HomeScreen, StudyCard, ReviewCard  
**study**：标准背词模式 - StudyScreen, WordCard, ChoiceOptions  
**challenge**：分级闯关模式 - ChallengeScreen, BattleScreen, Timer  
**leaderboard**：排行榜展示 - LeaderboardScreen, RankItem  
**ai_wordbook**：AI词本 - WordbookScreen, AIDialog  
**profile**：个人中心、设置 - ProfileScreen, SettingsScreen  

## 三、后端架构设计
### 3.1 后端整体架构（Mermaid）
```mermaid
graph TB
    subgraph "Spring Boot 后端架构"
        C["Controller层<br/>@RestController"]
        S["Service层<br/>@Service"]
        M["Mapper层<br/>@Mapper"]
        E["Entity实体层"]
        D["DTO数据传输层"]
        U["Utils工具类"]
        Config["配置类"]
        
        C --> S
        S --> M
        M --> E
        C --> D
        S --> U
        Config --> C
        Config --> S
        Config --> M
    end
    
    M --> DB[(MySQL)]
    C --> Client[前端客户端]
    
    style C fill:#ffccbc
    style S fill:#ffe0b2
    style M fill:#d7ccc8
```

### 3.2 后端模块划分

**用户模块**：com.beileme.auth - 登录注册、JWT认证  
**单词模块**：com.beileme.word - 单词学习、复习  
**闯关模块**：com.beileme.challenge - 闯关对战、积分  
**排行榜模块**：com.beileme.leaderboard - 积分排名  
**AI词本模块**：com.beileme.ai - 生词本、AI例句  
**公共模块**：com.beileme.common - 工具类、常量  

### 3.3 核心接口设计

**POST /api/auth/login**：用户登录 - 参数：{username, password} → 返回：{token, userInfo}  
**POST /api/auth/register**：用户注册 - 参数：{username, password, email} → 返回：{userId, token}  
**GET /api/words/daily**：每日单词 - 参数：无 → 返回：List<Word>  
**POST /api/words/learn**：学习记录 - 参数：{wordId, isCorrect} → 返回：{nextWord, progress}  
**POST /api/challenge/start**：开始闯关 - 参数：{level} → 返回：{questions, timeLimit}  
**POST /api/challenge/submit**：提交答案 - 参数：{challengeId, answers} → 返回：{score, correctCount}  
**GET /api/leaderboard**：获取排行榜 - 参数：{type: daily/weekly/total} → 返回：List<RankItem>  
**POST /api/wordbook/add**：加入生词本 - 参数：{wordId} → 返回：{success, wordbookId}  
**GET /api/wordbook/ai**：获取AI例句 - 参数：{wordId} → 返回：{examples, dialogues}  

## 四、系统交互流程
### 4.1 用户登录流程（Mermaid）
```mermaid
sequenceDiagram
    participant U as 用户
    participant F as Flutter前端
    participant B as Spring Boot后端
    participant DB as MySQL
    participant J as JWT
    
    U->>F: 输入用户名密码
    F->>F: 表单验证
    F->>B: POST /api/auth/login
    B->>DB: 查询用户信息
    DB-->>B: 返回用户数据
    B->>B: 密码验证
    B->>J: 生成JWT Token
    B-->>F: 返回Token+用户信息
    F->>F: 保存Token到SharedPreferences
    F->>U: 跳转到首页
```

### 4.2 单词学习流程（Mermaid）
```mermaid
sequenceDiagram
    participant U as 用户
    participant F as Flutter前端
    participant P as Provider
    participant B as 后端
    participant DB as 数据库
    
    U->>F: 点击"开始学习"
    F->>P: 请求今日单词
    P->>B: GET /api/words/daily
    B->>DB: 查询今日单词
    DB-->>B: 返回单词列表
    B-->>P: 返回单词数据
    P->>F: 更新状态
    F->>U: 显示第一个单词
    
    U->>F: 选择答案
    F->>P: 提交答案
    P->>B: POST /api/words/learn
    B->>DB: 保存学习记录
    B-->>P: 返回结果
    P->>F: 更新进度
    F->>U: 显示反馈
```

### 4.3 闯关对战流程（Mermaid）
```mermaid
sequenceDiagram
    participant U as 用户
    participant F as Flutter
    participant B as 后端
    participant DB as 数据库
    
    U->>F: 选择场次(初级/中级/高级)
    F->>B: POST /api/challenge/start
    B->>DB: 随机抽取题目
    DB-->>B: 返回题目列表
    B-->>F: 返回题目+时间限制
    
    loop 每道题
        F->>U: 显示题目
        U->>F: 选择答案
        F->>F: 计时暂停
        F->>B: 实时提交(可选)
        F->>U: 显示正确/错误
    end
    
    F->>B: POST /api/challenge/submit
    B->>B: 计算得分
    B->>DB: 保存成绩
    B-->>F: 返回结果
    F->>U: 显示结果页
```

## 五、技术选型确认表

**前端框架**：Flutter 3.x - 一套代码多端运行(iOS/Android)，性能接近原生，热重载开发效率高  
**状态管理**：Provider - 官方推荐，简单易用，与Flutter结合紧密，学习成本低  
**网络请求**：http包 - 轻量级，足够满足项目需求，避免引入过多依赖  
**本地存储**：SharedPreferences - 适合存储简单配置和Token，使用简单  
**后端框架**：Spring Boot 2.7+ - Java生态最成熟框架，集成方便，社区活跃  
**ORM框架**：MyBatis - SQL可控，性能好，适合复杂查询  
**数据库**：MySQL 8.0 - 稳定可靠，开源免费，满足中小型应用需求  
**认证方式**：JWT - 无状态，适合分布式部署  
**部署方式**：Docker - 环境一致性，便于扩展和迁移  

## 六、安全架构

### 6.1 认证与授权

- **JWT拦截器**：除登录注册外所有接口都需要Token验证  
- **密码加密**：BCrypt加密存储  
- **接口限流**：防止暴力请求  

### 6.2 数据安全

- **SQL注入防护**：MyBatis参数化查询  
- **XSS防护**：输入过滤  
- **敏感信息脱敏**：返回数据不包含密码等敏感字段  

### 6.3 传输安全

- **HTTPS**：生产环境强制使用  
- **Token过期机制**：设置合理有效期  

## 七、部署架构（Mermaid）
```mermaid
graph TB
    subgraph "生产环境"
        subgraph "负载均衡层"
            LB[Nginx]
        end
        
        subgraph "应用服务器集群"
            APP1[Spring Boot 实例1]
            APP2[Spring Boot 实例2]
        end
        
        subgraph "数据库层"
            DB_M[(MySQL Master)]
            DB_S[(MySQL Slave)]
        end
        
        subgraph "缓存层"
            REDIS[(Redis)]
        end
        
        subgraph "对象存储"
            OSS[静态资源<br/>单词图片/音频]
        end
    end
    
    User[用户] --> CDN[CDN加速]
    CDN --> LB
    LB --> APP1
    LB --> APP2
    APP1 --> DB_M
    APP2 --> DB_M
    APP1 --> DB_S
    APP2 --> DB_S
    APP1 --> REDIS
    APP2 --> REDIS
    APP1 --> OSS
    APP2 --> OSS
    
    DB_M --> DB_S
```

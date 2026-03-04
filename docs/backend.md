# backend.md   
# 背了么 - 后端架构说明文档

---

## 一、项目简介

**项目名称：** 背了么  
**项目定位：** 面向大学生的轻量级背单词应用  
**后端目标：** 提供稳定、高效、可扩展的单词学习与积分系统服务  

后端主要负责：

- 用户注册与登录认证
- 单词学习逻辑处理
- 分级闯关积分系统
- 全服排行榜计算
- AI例句生成服务
- 数据持久化与安全控制

---

## 二、整体架构设计

### 2.1 架构模式

采用经典三层架构 + RESTful API 设计：

```
Controller 层  →  Service 层  →  Mapper 层  →  MySQL
```

### 2.2 分层说明

| 层级 | 职责说明 |
|------|----------|
| Controller | 接收HTTP请求，参数校验，统一返回结果 |
| Service | 编写核心业务逻辑 |
| Mapper | 数据库访问层（MyBatis） |
| Config | JWT、跨域、拦截器等配置 |
| Common | 统一响应、异常类、工具类 |

---

## 三、技术栈说明

### 3.1 后端核心技术

| 技术 | 版本 | 说明 |
|------|------|------|
| Spring Boot | 3.4.11 | 主框架 |
| Java | 17 | LTS长期支持版本 |
| Maven | - | 项目构建管理 |
| Spring MVC | - | REST接口开发 |

---

### 3.2 数据持久层

| 技术 | 说明 |
|------|------|
| MyBatis | 手写SQL，支持复杂查询 |
| MySQL 8.0 | 主数据库 |
| HikariCP | 默认高性能连接池 |

选择 MyBatis 的原因：

- 排行榜涉及复杂排序SQL
- 闯关统计需要动态查询
- 更灵活控制SQL性能

---

### 3.3 安全认证方案

采用 JWT 无状态认证机制。

认证流程：

1. 用户登录成功  
2. 后端生成 JWT Token  
3. 客户端保存 Token  
4. 后续请求在请求头携带 Token  
5. 后端拦截器校验 Token 合法性  

优点：

- 无需Session  
- 支持移动端  
- 便于后期分布式扩展  

---

### 3.4 AI集成方案

集成火山引擎 Ark SDK，用于调用大模型API。

功能用途：

- 自动生成单词例句  
- 生成场景对话  
- 辅助理解单词用法  

调用流程：

```
用户添加单词 
      ↓
后端调用 Ark API 
      ↓
生成例句 / 对话 
      ↓
保存至数据库并返回前端
```

---

## 四、数据库设计

### 4.1 用户表（user）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint | 主键 |
| username | varchar(50) | 用户名 |
| password | varchar(255) | 加密密码 |
| total_score | int | 总积分 |
| level | int | 当前等级 |
| create_time | datetime | 注册时间 |

---

### 4.2 单词表（word）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint | 主键 |
| word | varchar(100) | 单词 |
| meaning | text | 释义 |
| phonetic | varchar(50) | 音标 |

---

### 4.3 用户单词表（user_word）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint | 主键 |
| user_id | bigint | 用户ID |
| word_id | bigint | 单词ID |
| status | int | 学习状态 |
| review_count | int | 复习次数 |

---

### 4.4 闯关记录表（battle_record）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint | 主键 |
| user_id | bigint | 用户ID |
| level_type | int | 关卡等级（1初级 2中级 3高级） |
| score | int | 本局得分 |
| create_time | datetime | 闯关时间 |

---

## 五、排行榜实现方案

### 5.1 实现逻辑

基于用户总积分进行排序：

```sql
SELECT username, total_score
FROM user
ORDER BY total_score DESC
LIMIT 100;
```

### 5.2 后期优化方案

- 接入 Redis 缓存排行榜  
- 使用 Redis ZSet 实现高性能排名  
- 定时刷新排行榜数据  

---

## 六、接口设计规范

### 6.1 统一响应格式

```json
{
  "code": 200,
  "message": "success",
  "data": {}
}
```

说明：

- code：状态码  
- message：提示信息  
- data：实际数据  

---

## 七、异常处理机制

- 使用 `@ControllerAdvice` 统一异常处理  
- 自定义 `BusinessException` 处理业务异常  
- 统一错误码管理  
- 记录日志便于排查问题  

---

## 八、项目结构

```
com.beileme
│
├── controller
├── service
├── mapper
├── entity
├── dto
├── config
└── common
```

---

## 九、运行方式

### 9.1 环境要求

- JDK 17+
- Maven 3.8+
- MySQL 8.0+
- （可选）Redis 6+

---

### 9.2 数据库准备

1. 创建数据库：

```sql
CREATE DATABASE beileme DEFAULT CHARSET utf8mb4;
```

2. 修改 `application.yml` 数据库配置：

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/beileme
    username: root
    password: 123456
```

---

### 9.3 启动步骤

#### 方式一：IDE 启动

1. 使用 IntelliJ IDEA 打开项目  
2. 等待 Maven 依赖下载完成  
3. 运行主启动类：

```
BeilemeApplication.java
```

---

#### 方式二：命令行启动

在项目根目录执行：

```bash
mvn clean install
mvn spring-boot:run
```

或打包运行：

```bash
mvn clean package
java -jar target/beileme-0.0.1-SNAPSHOT.jar
```

---

### 9.4 访问地址

默认端口：

```
http://localhost:8080
```

示例接口测试：

```
http://localhost:8080/api/auth/login
```

---

## 十、扩展规划

- 引入 Redis 缓存  
- Docker 容器化部署  
- 接入消息队列优化异步任务  
- 实现学习数据分析  
- 引入智能推荐学习路径  

---


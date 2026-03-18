

````markdown
# 项目规则（CLAUDE.md）

## 一、项目技术栈
- 前端：Flutter + Dart
- 后端：Spring Boot + MyBatis + Java 17
- 数据库：MySQL 8.0
- 构建工具：Maven
- 部署：Docker（规划中）

---

## 二、目录结构

beileme/
├── frontend/ # Flutter前端项目
│ ├── lib/
│ │ ├── main.dart # 应用入口
│ │ ├── core/ # 全局配置
│ │ │ ├── constants/ # 常量
│ │ │ └── theme/ # 主题样式
│ │ ├── features/ # 功能模块
│ │ │ ├── auth/ # 登录注册
│ │ │ ├── home/ # 首页
│ │ │ ├── study/ # 标准背词
│ │ │ ├── challenge/ # 分级闯关
│ │ │ ├── leaderboard/ # 排行榜
│ │ │ └── ai_wordbook/ # AI词本
│ │ ├── services/ # 接口请求
│ │ ├── models/ # 数据模型
│ │ └── widgets/ # 公共组件
│ └── pubspec.yaml
│
├── backend/ # Spring Boot后端项目
│ ├── src/main/java/com/beileme/
│ │ ├── controller/ # 接口层
│ │ ├── service/ # 业务逻辑层
│ │ ├── mapper/ # 数据访问层
│ │ ├── entity/ # 实体类
│ │ ├── dto/ # 数据传输对象
│ │ ├── config/ # 配置类
│ │ └── common/ # 公共工具类
│ └── pom.xml
│
├── docs/ # 文档目录
│ ├── architecture.md
│ ├── database.md
│ └── contributions/
│
└── README.md

---

## 三、AI开发规则（⭐核心）

- 在生成代码前，必须先说明实现思路
- 优先修改已有文件，避免随意创建新文件
- 优先复用已有代码，不重复造轮子
- 所有新增功能必须符合当前项目目录结构
- 后端接口必须包含：Controller + Service + Mapper + DTO
- 所有数据库操作必须提供SQL语句
- 所有接口必须给出示例请求和返回结果
- Flutter页面必须提供完整Widget结构（可运行）
- 禁止生成伪代码或不完整代码

---

## 四、代码规范

### 4.1 Flutter规范
- 使用 StatelessWidget / StatefulWidget 合理区分
- 使用 const 构造函数优化性能
- UI 与业务逻辑分离
- 网络请求统一放在 services 层
- 不在 Widget 中直接写复杂业务逻辑
- 命名规范：
  - 类名：PascalCase
  - 变量/方法：camelCase

---

### 4.2 Spring Boot规范
- Controller层：只处理请求和返回
- Service层：核心业务逻辑
- Mapper层：MyBatis SQL
- 使用DTO进行数据传输，避免直接暴露Entity
- 使用 @RestController + 统一返回结构
- 使用 @Slf4j 记录日志

---

### 4.3 数据库规范
- 表名使用 snake_case（如 user_info）
- 必须包含字段：
  - id（主键）
  - create_time
  - update_time
- 禁止使用 `SELECT *`
- 所有字段必须有注释
- 使用 InnoDB 引擎 + UTF8MB4

---

## 五、API规范

- RESTful 风格
- 请求前缀：`/api`
- 认证方式：JWT（登录/注册除外）

### 统一返回格式
```json
{
  "code": 200,
  "message": "success",
  "data": {}
}
````

### 状态码约定

* 200：成功
* 400：参数错误
* 401：未认证
* 403：无权限
* 500：服务器错误

---

## 六、异常与日志

### 异常处理

* 使用全局异常处理（@ControllerAdvice）
* 所有异常统一返回标准结构
* 不允许直接抛出原始异常给前端

### 日志规范

* 使用 @Slf4j
* error：系统错误
* warn：异常情况
* info：关键业务流程
* 禁止使用 System.out.println()

---

## 七、环境配置

* 使用 application-dev.yml / test / prod 区分环境
* 敏感信息使用环境变量（如数据库密码）
* 禁止硬编码配置

---

## 八、文档使用规则

* 开发前优先阅读 docs/ 下文档
* 架构问题参考 architecture.md
* 数据库设计参考 database.md

---

## 九、禁止事项（必须遵守）

❌ 前端不要修改后端返回结构
❌ 后端不要返回敏感信息（密码等）
❌ 不要硬编码配置
❌ 不要忽略异常处理
❌ 不要写不可运行代码
❌ 不要生成无用文件

---

## 十、Git提交规范

* feat: 新功能
* fix: 修复bug
* docs: 文档更新
* style: 代码格式
* refactor: 重构
* test: 测试
* chore: 构建/工具配置

---

## 十一、代码生成模板（AI必须遵守）

### 后端接口生成结构

必须包含：

1. Controller
2. Service
3. ServiceImpl
4. Mapper
5. XML（SQL）
6. DTO
7. 示例请求 + 返回

---

### Flutter页面生成结构

必须包含：

* 完整页面Widget
* 状态管理（基础State）
* API调用示例
* 基本UI结构（Scaffold）

---

## 十二、优先级原则

当规则冲突时：

1. 本文件优先
2. docs/ 文档优先
3. 通用最佳实践最后

```

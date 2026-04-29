# 软件架构设计贡献说明

**姓名**：[陈子怡]  
**学号**：[2312190329]  
**日期**：2026-03-18

## 我完成的工作

### 1. 架构设计

- [x] 后端架构设计（Spring Boot模块划分）
- [x] 数据库设计（ER图、核心表）

### 2. 技术选型

- **后端框架**：Spring Boot 2.7+ - Java生态最成熟框架
- **数据库**：MySQL 8.0 - 稳定可靠，满足需求

### 3. 环境搭建

- [x] 后端项目初始化

### 4. 文档编写

- [x] CLAUDE.md
- [x] database.md（含ER图、建表SQL）

## PR链接

PR #[16]：https://github.com/xi1xi1/Words/pull/16
PR #[17]：https://github.com/xi1xi1/Words/pull/17
PR #[18]：https://github.com/xi1xi1/Words/pull/18
PR #[19]：https://github.com/xi1xi1/Words/pull/19

## 遇到的问题和解决

### 问题1：数据库连接配置错误
- **现象：** 启动时报错 `Failed to configure a DataSource`
- **解决：** 创建 `application.yml` 配置文件，正确配置数据库连接信息

## 心得体会

通过本次作业，我学会了：

1. **如何编写AI辅助开发规则文件（CLAUDE.md）**，让后续开发更规范
2. **数据库设计规范**：ER图、字段注释、索引设计、外键约束
3. **Spring Boot项目从0到1的搭建流程**
4. **IDEA数据库工具的使用**：连接MySQL、执行SQL脚本
5. **配置文件的重要性**：application.yml的正确配置


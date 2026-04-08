CREATE DATABASE IF NOT EXISTS beileme
    DEFAULT CHARACTER SET utf8mb4
    COLLATE utf8mb4_general_ci;

USE beileme;

-- ========================================
-- 1. 用户表
-- ========================================
CREATE TABLE `user` (
                        `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
                        `username` VARCHAR(50) NOT NULL COMMENT '用户名（唯一）',
                        `password` VARCHAR(255) NOT NULL COMMENT '加密密码（BCrypt）',
                        `avatar` VARCHAR(255) DEFAULT NULL COMMENT '头像URL',

                        `total_score` INT NOT NULL DEFAULT 0 COMMENT '总积分（排行榜）',
                        `level` INT NOT NULL DEFAULT 1 COMMENT '用户等级',

                        `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

                        PRIMARY KEY (`id`),
                        UNIQUE KEY `uk_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

ALTER TABLE `user` ADD COLUMN `email` VARCHAR(100) DEFAULT NULL COMMENT '邮箱' AFTER `avatar`;
-- ========================================
-- 2. 单词表
-- ========================================
CREATE TABLE `word` (
                        `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
                        `word` VARCHAR(100) NOT NULL COMMENT '单词',

                        `meaning` JSON NOT NULL COMMENT '释义（JSON数组）',
                        `phonetic` VARCHAR(50) DEFAULT NULL COMMENT '音标',
                        `example` JSON DEFAULT NULL COMMENT '例句（JSON数组）',

                        `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

                        PRIMARY KEY (`id`),
                        UNIQUE KEY `uk_word` (`word`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='单词表';


-- ========================================
-- 3. 用户-单词关系表（⭐核心表）
-- ========================================
CREATE TABLE `user_word` (
                             `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',

                             `user_id` BIGINT NOT NULL COMMENT '用户ID',
                             `word_id` BIGINT NOT NULL COMMENT '单词ID',

                             `status` TINYINT NOT NULL DEFAULT 0 COMMENT '状态：0学习中 1已掌握 2生词本',

                             `review_count` INT NOT NULL DEFAULT 0 COMMENT '复习次数',
                             `next_review` DATETIME DEFAULT NULL COMMENT '下次复习时间',

                             `memory_score` DECIMAL(4,3) NOT NULL DEFAULT 0 COMMENT '记忆强度（0~1）',

                             `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                             `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

                             PRIMARY KEY (`id`),

                             UNIQUE KEY `uk_user_word` (`user_id`, `word_id`),

                             KEY `idx_review` (`user_id`, `status`, `next_review`),

                             CONSTRAINT `fk_uw_user`
                                 FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE CASCADE,

                             CONSTRAINT `fk_uw_word`
                                 FOREIGN KEY (`word_id`) REFERENCES `word`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户学习核心表';

-- 添加学习阶段字段
ALTER TABLE user_word 
ADD COLUMN `study_stage` TINYINT NOT NULL DEFAULT 1 
COMMENT '学习阶段：1-选义阶段 2-选例阶段 3-认词阶段' 
AFTER `status`;

-- 添加今日是否已完成字段（可选，用于判断今日是否还需复习）
ALTER TABLE user_word 
ADD COLUMN `today_mastered` TINYINT NOT NULL DEFAULT 0 
COMMENT '今日是否已掌握：0-未掌握 1-已掌握' 
AFTER `study_stage`;

-- 添加最后学习时间
ALTER TABLE user_word 
ADD COLUMN `last_study_time` DATETIME DEFAULT NULL 
COMMENT '最后学习时间' 
AFTER `today_mastered`;
-- ========================================
-- 4. 闯关记录表
-- ========================================
CREATE TABLE `battle_record` (
                                 `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',

                                 `user_id` BIGINT NOT NULL COMMENT '用户ID',

                                 `level_type` TINYINT NOT NULL COMMENT '关卡等级（1初级 2中级 3高级）',

                                 `score` INT NOT NULL DEFAULT 0,
                                 `correct_count` INT NOT NULL DEFAULT 0,
                                 `total_count` INT NOT NULL DEFAULT 0,

                                 `duration` INT DEFAULT NULL COMMENT '耗时（秒）',

                                 `details` JSON DEFAULT NULL COMMENT '答题详情（JSON）',

                                 `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

                                 PRIMARY KEY (`id`),

                                 KEY `idx_user_level` (`user_id`, `level_type`),
                                 KEY `idx_time` (`create_time`),

                                 CONSTRAINT `fk_br_user`
                                     FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='闯关记录表';


-- ========================================
-- 5. 学习统计表（按天聚合）
-- ========================================
CREATE TABLE `study_record` (
                                `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',

                                `user_id` BIGINT NOT NULL COMMENT '用户ID',

                                `study_count` INT DEFAULT 0 COMMENT '新学单词数',
                                `review_count` INT DEFAULT 0 COMMENT '复习次数',

                                `correct_rate` DECIMAL(4,3) DEFAULT 0 COMMENT '正确率（0~1）',

                                `study_date` DATE NOT NULL COMMENT '日期',

                                `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

                                PRIMARY KEY (`id`),

                                UNIQUE KEY `uk_user_date` (`user_id`, `study_date`),

                                CONSTRAINT `fk_sr_user`
                                    FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='每日学习统计表';


-- ========================================
-- 6. 初始化测试数据（可选）
-- ========================================
INSERT INTO word (word, meaning, phonetic, example) VALUES
                                                        ('abandon', '["v. 放弃", "n. 放任"]', '/əˈbændən/', '["He abandoned his plan."]'),
                                                        ('ability', '["n. 能力"]', '/əˈbɪləti/', '["She has ability."]'),
                                                        ('absent', '["adj. 缺席的"]', '/ˈæbsənt/', '["He was absent."]');

INSERT INTO user (username, password) VALUES
                                          ('test_user', '$2a$10$encrypted'),
                                          ('demo_user', '$2a$10$encrypted');

-- 控制器集成测试：重置用户 1 及闯关所需词库（随机抽题需全表至少约 20 词）
-- 密码明文 password，BCrypt 与 Auth 默认测试哈希一致

DELETE FROM study_record WHERE user_id = 1;
DELETE FROM battle_record WHERE user_id = 1;
DELETE FROM user_word WHERE user_id = 1;

INSERT INTO user (id, username, password, total_score, level) VALUES
    (1, 'jwt_challenge_user', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 1250, 3)
ON DUPLICATE KEY UPDATE
    username    = VALUES(username),
    password    = VALUES(password),
    total_score = VALUES(total_score),
    level       = VALUES(level);

INSERT INTO word (id, word, meaning, phonetic, example) VALUES
    (1, 'abandon', '["v. 放弃", "n. 放任"]', '/əˈbændən/', '["He abandoned his plan."]'),
    (2, 'ability', '["n. 能力", "才能"]', '/əˈbɪləti/', '["She has the ability to learn fast."]'),
    (3, 'absent', '["adj. 缺席的", "心不在焉的"]', '/ˈæbsənt/', '["He was absent from school."]'),
    (4, 'accept', '["v. 接受", "同意"]', '/əkˈsept/', '["Please accept my apology."]'),
    (5, 'achieve', '["v. 实现", "取得"]', '/əˈtʃiːv/', '["You can achieve your goals."]'),
    (6, 'active', '["adj. 活跃的", "积极的"]', '/ˈæktɪv/', '["She is very active in class."]'),
    (7, 'actual', '["adj. 实际的", "真实的"]', '/ˈæktʃuəl/', '["The actual cost was lower."]'),
    (8, 'advice', '["n. 建议", "劝告"]', '/ədˈvaɪs/', '["Thanks for your advice."]'),
    (9, 'affect', '["v. 影响", "感动"]', '/əˈfekt/', '["This will affect everyone."]'),
    (10, 'agree', '["v. 同意", "赞成"]', '/əˈɡriː/', '["I agree with you."]'),
    (11, 'allow', '["v. 允许", "准许"]', '/əˈlaʊ/', '["Please allow me to explain."]'),
    (12, 'answer', '["n. 答案", "v. 回答"]', '/ˈɑːnsər/', '["Do you know the answer?"]'),
    (13, 'apply', '["v. 申请", "应用"]', '/əˈplaɪ/', '["You should apply for the job."]'),
    (14, 'argue', '["v. 争论", "辩论"]', '/ˈɑːrɡjuː/', '["They argue every day."]'),
    (15, 'arrive', '["v. 到达", "抵达"]', '/əˈraɪv/', '["What time will you arrive?"]'),
    (16, 'attack', '["v. 攻击", "n. 进攻"]', '/əˈtæk/', '["The dog tried to attack."]'),
    (17, 'attend', '["v. 参加", "出席"]', '/əˈtend/', '["Did you attend the meeting?"]'),
    (18, 'avoid', '["v. 避免", "避开"]', '/əˈvɔɪd/', '["Try to avoid mistakes."]'),
    (19, 'become', '["v. 变成", "成为"]', '/bɪˈkʌm/', '["She wants to become a doctor."]'),
    (20, 'believe', '["v. 相信", "认为"]', '/bɪˈliːv/', '["I believe in you."]'),
    (21, 'benefit', '["n. 好处", "v. 受益"]', '/ˈbenɪfɪt/', '["This will benefit everyone."]'),
    (22, 'brief', '["adj. 简短的", "简洁的"]', '/briːf/', '["Please keep it brief."]'),
    (23, 'careful', '["adj. 小心的", "谨慎的"]', '/ˈkerfl/', '["Be careful on the road."]'),
    (24, 'certain', '["adj. 确定的", "肯定的"]', '/ˈsɜːrtn/', '["Are you certain about that?"]'),
    (25, 'chance', '["n. 机会", "可能性"]', '/tʃæns/', '["Take a chance on it."]')
ON DUPLICATE KEY UPDATE
    word    = VALUES(word),
    meaning = VALUES(meaning),
    phonetic = VALUES(phonetic),
    example = VALUES(example);

-- 生词本等：用户 1 已将单词 1 加入生词本（status=2），stage=1 供 /words/learn 校验
INSERT INTO user_word (user_id, word_id, status, study_stage, today_mastered, review_count, next_review, memory_score)
VALUES (1, 1, 2, 1, 0, 0, NOW(), 0.000);

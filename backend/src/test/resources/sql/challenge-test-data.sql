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
    (2, 'ability', '["n. 能力"]', '/əˈbɪləti/', '["She has ability."]'),
    (3, 'absent', '["adj. 缺席的"]', '/ˈæbsənt/', '["He was absent."]'),
    (4, 'bench_w04', '["n. 测"]', NULL, '[]'),
    (5, 'bench_w05', '["n. 测"]', NULL, '[]'),
    (6, 'bench_w06', '["n. 测"]', NULL, '[]'),
    (7, 'bench_w07', '["n. 测"]', NULL, '[]'),
    (8, 'bench_w08', '["n. 测"]', NULL, '[]'),
    (9, 'bench_w09', '["n. 测"]', NULL, '[]'),
    (10, 'bench_w10', '["n. 测"]', NULL, '[]'),
    (11, 'bench_w11', '["n. 测"]', NULL, '[]'),
    (12, 'bench_w12', '["n. 测"]', NULL, '[]'),
    (13, 'bench_w13', '["n. 测"]', NULL, '[]'),
    (14, 'bench_w14', '["n. 测"]', NULL, '[]'),
    (15, 'bench_w15', '["n. 测"]', NULL, '[]'),
    (16, 'bench_w16', '["n. 测"]', NULL, '[]'),
    (17, 'bench_w17', '["n. 测"]', NULL, '[]'),
    (18, 'bench_w18', '["n. 测"]', NULL, '[]'),
    (19, 'bench_w19', '["n. 测"]', NULL, '[]'),
    (20, 'bench_w20', '["n. 测"]', NULL, '[]'),
    (21, 'bench_w21', '["n. 测"]', NULL, '[]'),
    (22, 'bench_w22', '["n. 测"]', NULL, '[]'),
    (23, 'bench_w23', '["n. 测"]', NULL, '[]'),
    (24, 'bench_w24', '["n. 测"]', NULL, '[]'),
    (25, 'bench_w25', '["n. 测"]', NULL, '[]')
ON DUPLICATE KEY UPDATE
    word    = VALUES(word),
    meaning = VALUES(meaning),
    phonetic = VALUES(phonetic),
    example = VALUES(example);

-- 生词本等：用户 1 已将单词 1 加入生词本（status=2），stage=1 供 /words/learn 校验
INSERT INTO user_word (user_id, word_id, status, study_stage, today_mastered, review_count, next_review, memory_score)
VALUES (1, 1, 2, 1, 0, 0, NOW(), 0.000);

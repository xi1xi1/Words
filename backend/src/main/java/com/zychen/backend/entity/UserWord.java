package com.zychen.backend.entity;

import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class UserWord {
    private Long id;
    private Long userId;
    private Long wordId;
    private Integer status;        // 0学习中 1已掌握 2生词本
    private Integer studyStage;    // 1-选义阶段 2-选例阶段 3-认词阶段（新增）
    private Integer todayMastered; // 今日是否已掌握（新增）
    private Integer reviewCount;
    private LocalDateTime nextReview;
    private BigDecimal memoryScore;
    private LocalDateTime lastStudyTime; // 最后学习时间（新增）
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
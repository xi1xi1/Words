package com.zychen.backend.entity;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 每日学习统计表 study_record 对应实体。
 */
@Data
public class StudyRecord {
    private Long id;
    private Long userId;
    private Integer studyCount;
    private Integer reviewCount;
    private BigDecimal correctRate;
    private LocalDate studyDate;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}

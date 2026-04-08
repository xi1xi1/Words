package com.zychen.backend.dto.request;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * 写入 study_record 时的聚合字段（按 user_id + study_date 插入或整行更新）。
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class StudyRecordWriteDTO {

    private Long userId;
    private LocalDate studyDate;
    private Integer studyCount;
    private Integer reviewCount;
    private BigDecimal correctRate;
}

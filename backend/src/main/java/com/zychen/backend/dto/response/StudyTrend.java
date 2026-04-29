package com.zychen.backend.dto.response;
import lombok.Data;
import java.time.LocalDate;

@Data
public class StudyTrend {

    private LocalDate date;          // 日期
    private Integer studyCount;      // 新学单词数
    private Integer reviewCount;     // 复习次数
    private Double correctRate;      // 正确率（0-1）
}

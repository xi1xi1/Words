package com.zychen.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 某月内有 study_record 的日期列表（yyyy-MM-dd）。
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CalendarDTO {
    private Integer year;
    private Integer month;
    private List<String> studyDates;
}

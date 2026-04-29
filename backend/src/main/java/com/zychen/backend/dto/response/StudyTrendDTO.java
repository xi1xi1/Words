package com.zychen.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * 对应 api.yaml components/schemas/StudyTrend
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StudyTrendDTO {
    private String date;
    private Integer studyCount;
    private Integer reviewCount;
    private BigDecimal correctRate;
}

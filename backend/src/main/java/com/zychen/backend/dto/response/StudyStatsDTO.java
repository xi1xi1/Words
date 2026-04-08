package com.zychen.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 对应 api.yaml components/schemas/StudyStats
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StudyStatsDTO {
    private Integer todayStudy;
    private Integer todayReview;
    private Integer totalWords;
    private Integer masteredWords;
    private Integer wordbookWords;
    private Integer dueReviewCount;
    private Integer totalScore;
    private Integer level;
}

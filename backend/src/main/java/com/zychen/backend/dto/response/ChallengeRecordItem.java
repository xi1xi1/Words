package com.zychen.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChallengeRecordItem {

    private Long id;
    private Integer levelType;
    private String levelName;
    private Integer score;
    private Integer correctCount;
    private Integer totalCount;
    private Double correctRate;
    private LocalDateTime createTime;
    private Integer duration;
}

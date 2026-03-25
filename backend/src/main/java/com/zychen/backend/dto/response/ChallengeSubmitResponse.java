package com.zychen.backend.dto.response;

import lombok.Data;

@Data
public class ChallengeSubmitResponse {

    private Integer score;          // 本局得分
    private Integer correctCount;   // 正确答题数
    private Integer totalCount;     // 总题数
    private Double accuracy;        // 正确率（0-1）
    private Integer addedScore;     // 增加的积分
    private Integer totalScore;     // 累计总积分
}
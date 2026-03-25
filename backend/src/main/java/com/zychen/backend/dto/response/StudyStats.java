package com.zychen.backend.dto.response;

import lombok.Data;

@Data
public class StudyStats {

    private Integer todayStudy;      // 今日新学单词数
    private Integer todayReview;     // 今日复习次数
    private Integer totalWords;      // 累计学习单词数
    private Integer masteredWords;   // 已掌握单词数
    private Integer wordbookWords;   // 生词本单词数
    private Integer dueReviewCount;  // 待复习单词数
    private Integer totalScore;      // 总积分
    private Integer level;           // 用户等级
}

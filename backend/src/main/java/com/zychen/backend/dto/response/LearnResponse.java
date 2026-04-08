package com.zychen.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LearnResponse {
    private NextWordInfo nextWord;  // 下一个要学习的单词（null表示今日完成）
    private Integer completedCount; // 今日已完成单词数
    private Integer totalCount;     // 今日需要学习的单词总数
}
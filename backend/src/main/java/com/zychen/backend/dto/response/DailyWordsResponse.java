package com.zychen.backend.dto.response;

import lombok.Data;
import java.util.List;

@Data
public class DailyWordsResponse {

    private List<Word> newWords;
    private List<Word> reviewWords;
    private Integer total;
    /** 可学词总数：未分配新词 + 已分配但未掌握的新词（SELECT COUNT，无表结构变更） */
    private Integer learnableWordCount;
    /** 本人已到期的可复习词数（SELECT COUNT，无表结构变更） */
    private Integer reviewableWordCount;
}
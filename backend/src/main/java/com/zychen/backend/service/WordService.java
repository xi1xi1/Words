// src/main/java/com/zychen/backend/service/WordService.java
package com.zychen.backend.service;

import com.zychen.backend.dto.request.LearnRequest;
import com.zychen.backend.dto.response.DailyWordsResponse;
import com.zychen.backend.dto.response.LearnResponse;
import com.zychen.backend.dto.response.Word;

import java.util.List;

public interface WordService {

    /**
     * 获取今日单词（新词 + 复习词）
     */
    DailyWordsResponse getDailyWords(Long userId);

    /**
     * 提交学习结果，返回下一个单词
     */
    LearnResponse submitLearnResult(Long userId, LearnRequest request);

    /**
     * 搜索单词
     */
    List<Word> searchWords(String keyword, Integer page, Integer size);

    /**
     * 获取单词详情
     */
    Word getWordDetail(Long wordId);

    /**
     * 当今日待学队列耗尽时，自动补充一批新单词到用户的 `user_word` 中。
     * 补充后需满足：状态=0、today_mastered=0、next_review <= NOW()，使其能进入今日学习队列。
     */
    void replenishDailyNewWords(Long userId);
}
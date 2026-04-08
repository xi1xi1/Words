package com.zychen.backend.service;

import com.zychen.backend.dto.response.WordbookPage;

import java.util.Map;

public interface WordbookService {

    /**
     * 加入生词本：无记录则插入 status=2；已有记录则更新为 status=2
     */
    void addToWordbook(Long userId, Long wordId);

    /**
     * 移出生词本：将 status 置为 0（学习中）
     */
    void removeFromWordbook(Long userId, Long wordId);

    /**
     * 分页生词本列表（关联 word 详情）
     */
    WordbookPage getWordbookList(Long userId, int page, int size);

    /**
     * 生词本词条总数（status=2）
     */
    int getWordbookCount(Long userId);

    /**
     * 获取 AI 生成例句（同步调用）
     *
     * @return data: { word, examples（原例句）, aiExample（AI例句） }
     */
    Map<String, Object> getAIContent(Long userId, Long wordId);
}

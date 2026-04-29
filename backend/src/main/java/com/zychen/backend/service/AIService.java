package com.zychen.backend.service;

import com.zychen.backend.dto.response.AIMemoryContent;

/**
 * 火山方舟：根据单词与释义生成英文例句。
 */
public interface AIService {

    /**
     * 调用模型生成一句英文例句（仅句子正文）。
     */
    String generateExample(String word, String meaning);

    /**
     * 异步：生成例句并合并写入 {@code word.example}（JSON 数组）。
     */
    void generateAndPersistExample(Long wordId, String word, String meaning);

    /**
     * 生成 AI 联想记忆内容（谐音/拆词/故事/总结）。
     */
    AIMemoryContent generateMemoryContent(String word, String meaning);
}

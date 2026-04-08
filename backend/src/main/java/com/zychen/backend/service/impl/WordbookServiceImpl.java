package com.zychen.backend.service.impl;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zychen.backend.common.BusinessException;
import com.zychen.backend.dto.response.WordbookListItem;
import com.zychen.backend.dto.response.WordbookPage;
import com.zychen.backend.entity.UserWord;
import com.zychen.backend.entity.Word;
import com.zychen.backend.mapper.UserWordMapper;
import com.zychen.backend.mapper.WordMapper;
import com.zychen.backend.service.AIService;
import com.zychen.backend.service.WordbookService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Collections;
import java.util.Map;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class WordbookServiceImpl implements WordbookService {

    private static final int MAX_PAGE_SIZE = 100;

    private final UserWordMapper userWordMapper;
    private final WordMapper wordMapper;
    private final ObjectMapper objectMapper;
    private final AIService aiService;

    @Override
    @Transactional
    public void addToWordbook(Long userId, Long wordId) {
        Word w = wordMapper.findById(wordId);
        if (w == null) {
            throw new BusinessException(404, "单词不存在");
        }
        UserWord uw = userWordMapper.findByUserIdAndWordId(userId, wordId);
        if (uw == null) {
            UserWord row = new UserWord();
            row.setUserId(userId);
            row.setWordId(wordId);
            row.setStatus(2);
            row.setStudyStage(1);
            row.setTodayMastered(0);
            row.setReviewCount(0);
            row.setNextReview(LocalDateTime.now());
            row.setMemoryScore(BigDecimal.ZERO);
            row.setLastStudyTime(null);
            userWordMapper.insert(row);
            log.info("生词本新建记录: userId={}, wordId={}", userId, wordId);
        } else {
            userWordMapper.addToWordbook(userId, wordId);
            log.info("生词本更新状态: userId={}, wordId={}", userId, wordId);
        }
        String meaning = w.getMeaning() != null ? w.getMeaning() : "";
        aiService.generateAndPersistExample(w.getId(), w.getWord(), meaning);
    }

    @Override
    @Transactional
    public void removeFromWordbook(Long userId, Long wordId) {
        int rows = userWordMapper.removeFromWordbook(userId, wordId);
        if (rows == 0) {
            throw new BusinessException(404, "未在生词本中");
        }
        log.info("移出生词本: userId={}, wordId={}", userId, wordId);
    }

    @Override
    public WordbookPage getWordbookList(Long userId, int page, int size) {
        int safePage = Math.max(page, 1);
        int safeSize = Math.min(Math.max(size, 1), MAX_PAGE_SIZE);
        int offset = (safePage - 1) * safeSize;

        long total = userWordMapper.countWordbook(userId);
        List<UserWord> rows = userWordMapper.getWordbook(userId, offset, safeSize);

        List<WordbookListItem> content = rows.stream()
                .map(this::toListItem)
                .collect(Collectors.toList());

        return WordbookPage.builder()
                .content(content)
                .total(total)
                .page(safePage)
                .size(safeSize)
                .build();
    }

    @Override
    public int getWordbookCount(Long userId) {
        return userWordMapper.countWordbook(userId);
    }

    @Override
    public Map<String, Object> getAIContent(Long userId, Long wordId) {
        Word w = wordMapper.findById(wordId);
        if (w == null) {
            throw new BusinessException(404, "单词不存在");
        }

        // 原例句（example JSON 数组）
        List<String> examples = parseJsonArray(w.getExample());

        // AI 提示词：优先使用“第一个释义”，避免把 JSON 整段塞进 prompt
        List<String> meanings = parseJsonArray(w.getMeaning());
        String meaningForPrompt = meanings.isEmpty() ? "" : meanings.get(0);

        // 同步调用火山方舟生成“一句英文例句”
        String aiExample = aiService.generateExample(w.getWord(), meaningForPrompt);
        if (aiExample == null) {
            aiExample = "";
        }

        Map<String, Object> data = new HashMap<>();
        data.put("word", w.getWord());
        data.put("examples", examples);
        data.put("aiExample", aiExample);
        return data;
    }

    private WordbookListItem toListItem(UserWord uw) {
        Word w = wordMapper.findById(uw.getWordId());
        if (w == null) {
            log.warn("生词本条目关联单词缺失: userWordId={}, wordId={}", uw.getId(), uw.getWordId());
            return WordbookListItem.builder()
                    .id(uw.getId())
                    .wordId(uw.getWordId())
                    .word("")
                    .meaning(Collections.emptyList())
                    .phonetic(null)
                    .example(Collections.emptyList())
                    .addTime(uw.getCreateTime())
                    .build();
        }
        return WordbookListItem.builder()
                .id(uw.getId())
                .wordId(w.getId())
                .word(w.getWord())
                .meaning(parseJsonArray(w.getMeaning()))
                .phonetic(w.getPhonetic())
                .example(parseJsonArray(w.getExample()))
                .addTime(uw.getCreateTime())
                .build();
    }

    private List<String> parseJsonArray(String json) {
        if (json == null || json.isBlank()) {
            return new ArrayList<>();
        }
        try {
            return objectMapper.readValue(json, new TypeReference<List<String>>() {});
        } catch (Exception e) {
            log.warn("JSON 解析失败，返回空列表: {}", e.getMessage());
            return new ArrayList<>();
        }
    }
}

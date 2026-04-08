package com.zychen.backend.controller;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zychen.backend.common.BusinessException;
import com.zychen.backend.dto.response.ApiResponse;
import com.zychen.backend.dto.response.WordbookPage;
import com.zychen.backend.entity.Word;
import com.zychen.backend.mapper.WordMapper;
import com.zychen.backend.service.WordbookService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/wordbook")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class WordbookController {

    private final WordbookService wordbookService;
    private final WordMapper wordMapper;
    private final ObjectMapper objectMapper;

    /**
     * 获取生词本列表
     * GET /api/wordbook/list
     */
    @GetMapping("/list")
    public ApiResponse<WordbookPage> getWordbookList(
            @RequestAttribute("userId") Long userId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("GET /api/wordbook/list - page: {}, size: {}", page, size);
        WordbookPage data = wordbookService.getWordbookList(userId, page, size);
        return ApiResponse.success(data);
    }

    /**
     * 添加单词到生词本
     * POST /api/wordbook/add/{wordId}
     */
    @PostMapping("/add/{wordId}")
    public ApiResponse<Void> addToWordbook(
            @RequestAttribute("userId") Long userId,
            @PathVariable Long wordId) {
        log.info("POST /api/wordbook/add/{}", wordId);
        wordbookService.addToWordbook(userId, wordId);
        return ApiResponse.success("已加入生词本", null);
    }

    /**
     * 从生词本移除
     * DELETE /api/wordbook/remove/{wordId}
     */
    @DeleteMapping("/remove/{wordId}")
    public ApiResponse<Void> removeFromWordbook(
            @RequestAttribute("userId") Long userId,
            @PathVariable Long wordId) {
        log.info("DELETE /api/wordbook/remove/{}", wordId);
        wordbookService.removeFromWordbook(userId, wordId);
        return ApiResponse.success("已移除", null);
    }

    /**
     * 获取 AI 相关内容：从词库 example 字段解析例句；对话占位（待对接 AI）
     * GET /api/wordbook/ai/{wordId}
     */
    @GetMapping("/ai/{wordId}")
    public ApiResponse<Map<String, Object>> getAIContent(
            @RequestAttribute("userId") Long userId,
            @PathVariable Long wordId) {
        log.info("GET /api/wordbook/ai/{} userId={}", wordId, userId);
        Word word = wordMapper.findById(wordId);
        if (word == null) {
            throw new BusinessException(404, "单词不存在");
        }
        List<String> examples = parseJsonArray(word.getExample());
        Map<String, Object> data = new HashMap<>();
        data.put("word", word.getWord());
        data.put("examples", examples);
        data.put("dialogues", List.of());
        return ApiResponse.success(data);
    }

    private List<String> parseJsonArray(String json) {
        if (json == null || json.isBlank()) {
            return new ArrayList<>();
        }
        try {
            return objectMapper.readValue(json, new TypeReference<List<String>>() {});
        } catch (Exception e) {
            return new ArrayList<>();
        }
    }
}

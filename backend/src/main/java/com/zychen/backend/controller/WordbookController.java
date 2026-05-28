package com.zychen.backend.controller;

import com.zychen.backend.dto.response.AIMemoryContent;
import com.zychen.backend.dto.response.ApiResponse;
import com.zychen.backend.dto.response.WordbookPage;
import com.zychen.backend.service.WordbookService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/wordbook")
@RequiredArgsConstructor
public class WordbookController {

    private final WordbookService wordbookService;

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
     * 获取 AI 生成例句
     * GET /api/wordbook/ai/{wordId}
     */
    @GetMapping("/ai/{wordId}")
    public ApiResponse<AIMemoryContent> getAIContent(
            @RequestAttribute("userId") Long userId,
            @PathVariable Long wordId) {
        log.info("GET /api/wordbook/ai/{} userId={}", wordId, userId);
        AIMemoryContent data = wordbookService.getAIContent(userId, wordId);
        return ApiResponse.success(data);
    }
}

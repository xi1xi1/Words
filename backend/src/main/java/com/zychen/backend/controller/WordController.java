package com.zychen.backend.controller;

import com.zychen.backend.dto.request.LearnRequest;
import com.zychen.backend.dto.response.ApiResponse;
import com.zychen.backend.dto.response.DailyWordsResponse;
import com.zychen.backend.dto.response.LearnResponse;
import com.zychen.backend.dto.response.Word;
import com.zychen.backend.service.WordService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;


import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/words")
@RequiredArgsConstructor
public class WordController {

    private final WordService wordService;

    /**
     * 获取今日单词
     * GET /api/words/daily
     */
    @GetMapping("/daily")
    public ApiResponse<DailyWordsResponse> getDailyWords(@RequestAttribute("userId") Long userId) {
        DailyWordsResponse response = wordService.getDailyWords(userId);
        return ApiResponse.success(response);
    }

    /**
     * 提交学习结果
     * POST /api/words/learn
     */
    @PostMapping("/learn")
    public ApiResponse<LearnResponse> submitLearnResult(
            @RequestAttribute("userId") Long userId,
            @Valid @RequestBody LearnRequest request) {
        LearnResponse response = wordService.submitLearnResult(userId, request);
        return ApiResponse.success(response);
    }

    /**
     * 搜索单词
     * GET /api/words/search
     */
    @GetMapping("/search")
    public ApiResponse<List<Word>> searchWords(
            @RequestParam String keyword,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "20") Integer size) {
        List<Word> words = wordService.searchWords(keyword, page, size);
        return ApiResponse.success(words);
    }

    /**
     * 获取单词详情
     * GET /api/words/{id}
     */
    @GetMapping("/{id}")
    public ApiResponse<Word> getWordDetail(@PathVariable Long id) {
        Word word = wordService.getWordDetail(id);
        return ApiResponse.success(word);
    }
}
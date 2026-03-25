package com.zychen.backend.controller;

import com.zychen.backend.dto.request.AddToWordbookRequest;
import com.zychen.backend.dto.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@Slf4j
@RestController
@RequestMapping("/api/wordbook")
@CrossOrigin(origins = "*")
public class WordbookController {

    // Mock 生词本数据
    private final List<Map<String, Object>> mockWordbook = new ArrayList<>();

    public WordbookController() {
        // 初始化 Mock 数据
        Map<String, Object> item1 = new HashMap<>();
        item1.put("id", 10001L);
        item1.put("wordId", 1L);
        item1.put("word", "abandon");
        item1.put("meaning", List.of("v. 放弃", "n. 放任"));
        item1.put("phonetic", "/əˈbændən/");
        item1.put("addTime", "2026-03-18 10:30:00");
        mockWordbook.add(item1);
    }

    /**
     * 获取生词本列表
     * GET /api/wordbook/list
     *
     * 示例请求：
     * GET /api/wordbook/list?page=1&size=20
     *
     * 示例返回：
     * {
     *   "code": 200,
     *   "message": "success",
     *   "data": {
     *     "content": [...],
     *     "total": 128,
     *     "page": 1,
     *     "size": 20
     *   }
     * }
     */
    @GetMapping("/list")
    public ApiResponse<Map<String, Object>> getWordbookList(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestHeader(value = "Authorization", required = false) String auth) {
        log.info("GET /api/wordbook/list - page: {}, size: {}", page, size);

        // TODO: 从数据库查询生词本列表

        // 模拟分页
        List<Map<String, Object>> content = mockWordbook;
        int total = mockWordbook.size();

        Map<String, Object> result = new HashMap<>();
        result.put("content", content);
        result.put("total", total);
        result.put("page", page);
        result.put("size", size);

        return ApiResponse.success(result);
    }

    /**
     * 添加单词到生词本
     * POST /api/wordbook/add
     *
     * 示例请求：
     * {
     *   "wordId": 1
     * }
     *
     * 示例返回：
     * {
     *   "code": 200,
     *   "message": "已加入生词本",
     *   "data": null
     * }
     */
    @PostMapping("/add")
    public ApiResponse<Void> addToWordbook(
            @Valid @RequestBody AddToWordbookRequest request,
            @RequestHeader(value = "Authorization", required = false) String auth) {
        log.info("POST /api/wordbook/add - wordId: {}", request.getWordId());

        // TODO: 检查单词是否存在，是否已在生词本，加入生词本

        return ApiResponse.success("已加入生词本", null);
    }

    /**
     * 从生词本移除
     * DELETE /api/wordbook/remove/{wordId}
     *
     * 示例请求：
     * DELETE /api/wordbook/remove/1
     *
     * 示例返回：
     * {
     *   "code": 200,
     *   "message": "已移除",
     *   "data": null
     * }
     */
    @DeleteMapping("/remove/{wordId}")
    public ApiResponse<Void> removeFromWordbook(
            @PathVariable Long wordId,
            @RequestHeader(value = "Authorization", required = false) String auth) {
        log.info("DELETE /api/wordbook/remove/{}", wordId);

        // TODO: 从生词本移除该单词

        return ApiResponse.success("已移除", null);
    }

    /**
     * 获取AI生成内容（例句和对话）
     * GET /api/wordbook/ai/{wordId}
     *
     * 示例返回：
     * {
     *   "code": 200,
     *   "message": "success",
     *   "data": {
     *     "word": "abandon",
     *     "examples": ["He abandoned his plan.", "They abandoned the city."],
     *     "dialogues": [
     *       {
     *         "scene": "告别场景",
     *         "conversation": ["A: Why did you leave?", "B: I had to abandon the project."]
     *       }
     *     ]
     *   }
     * }
     */
    @GetMapping("/ai/{wordId}")
    public ApiResponse<Map<String, Object>> getAIContent(
            @PathVariable Long wordId,
            @RequestHeader(value = "Authorization", required = false) String auth) {
        log.info("GET /api/wordbook/ai/{}", wordId);

        // TODO: 调用AI接口生成例句和对话

        // Mock AI 返回数据
        Map<String, Object> response = new HashMap<>();
        response.put("word", "abandon");
        response.put("examples", List.of(
                "He abandoned his plan.",
                "They abandoned the city.",
                "She abandoned her dream of becoming a singer."
        ));

        List<Map<String, Object>> dialogues = new ArrayList<>();
        Map<String, Object> dialogue1 = new HashMap<>();
        dialogue1.put("scene", "告别场景");
        dialogue1.put("conversation", List.of(
                "A: Why did you leave the project?",
                "B: I had to abandon it due to time constraints."
        ));
        dialogues.add(dialogue1);

        response.put("dialogues", dialogues);

        return ApiResponse.success(response);
    }
}
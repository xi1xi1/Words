package com.zychen.backend.controller;

import com.zychen.backend.dto.request.LearnRequest;
import com.zychen.backend.dto.response.ApiResponse;
import com.zychen.backend.dto.response.DailyWordsResponse;
import com.zychen.backend.dto.response.Word;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@Slf4j
@RestController
@RequestMapping("/api/words")
@CrossOrigin(origins = "*")
public class WordController {

    // Mock 单词数据
    private final List<Word> mockWords = Arrays.asList(
            createWord(1L, "abandon", List.of("v. 放弃", "n. 放任"), "/əˈbændən/",
                    List.of("He abandoned his plan.", "They abandoned the city.")),
            createWord(2L, "ability", List.of("n. 能力", "才能"), "/əˈbɪləti/",
                    List.of("She has the ability to learn fast.")),
            createWord(3L, "absent", List.of("adj. 缺席的"), "/ˈæbsənt/",
                    List.of("He was absent from school.")),
            createWord(4L, "abundant", List.of("adj. 丰富的", "充裕的"), "/əˈbʌndənt/",
                    List.of("The area is abundant in wildlife."))
    );

    private Word createWord(Long id, String word, List<String> meaning, String phonetic, List<String> example) {
        Word w = new Word();
        w.setId(id);
        w.setWord(word);
        w.setMeaning(meaning);
        w.setPhonetic(phonetic);
        w.setExample(example);
        return w;
    }

    /**
     * 获取今日学习单词
     * GET /api/words/daily
     */
    @GetMapping("/daily")
    public ApiResponse<DailyWordsResponse> getDailyWords(
            @RequestHeader(value = "Authorization", required = false) String auth) {
        log.info("GET /api/words/daily");

        // TODO: 根据用户学习计划返回今日单词
        DailyWordsResponse response = new DailyWordsResponse();
        response.setNewWords(mockWords.subList(0, 2));      // 2个新词
        response.setReviewWords(mockWords.subList(2, 3));   // 1个复习词

        return ApiResponse.success(response);
    }

    /**
     * 提交学习结果
     * POST /api/words/learn
     */
    @PostMapping("/learn")
    public ApiResponse<Map<String, Object>> submitLearnResult(
            @Valid @RequestBody LearnRequest request,
            @RequestHeader(value = "Authorization", required = false) String auth) {
        log.info("POST /api/words/learn - wordId: {}, isCorrect: {}",
                request.getWordId(), request.getIsCorrect());

        // TODO: 更新用户学习记录，更新复习计划
        Map<String, Object> response = new HashMap<>();

        // 下一个单词
        Map<String, Object> nextWord = new HashMap<>();
        nextWord.put("id", 2L);
        nextWord.put("word", "ability");
        nextWord.put("meaning", List.of("n. 能力", "才能"));
        nextWord.put("phonetic", "/əˈbɪləti/");

        // 学习进度
        Map<String, Object> progress = new HashMap<>();
        progress.put("learned", 1);
        progress.put("total", 5);
        progress.put("percentage", 20);

        response.put("nextWord", nextWord);
        response.put("progress", progress);

        return ApiResponse.success(response);
    }

    /**
     * 搜索单词
     * GET /api/words/search
     */
    @GetMapping("/search")
    public ApiResponse<Map<String, Object>> searchWords(
            @RequestParam String keyword,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestHeader(value = "Authorization", required = false) String auth) {
        log.info("GET /api/words/search - keyword: {}, page: {}, size: {}", keyword, page, size);

        // TODO: 从数据库搜索单词
        List<Word> filtered = mockWords.stream()
                .filter(w -> w.getWord().contains(keyword))
                .toList();

        Map<String, Object> result = new HashMap<>();
        result.put("content", filtered);
        result.put("total", filtered.size());
        result.put("page", page);
        result.put("size", size);

        return ApiResponse.success(result);
    }

    /**
     * 获取单词详情
     * GET /api/words/{id}
     */
    @GetMapping("/{id}")
    public ApiResponse<Word> getWordDetail(
            @PathVariable Long id,
            @RequestHeader(value = "Authorization", required = false) String auth) {
        log.info("GET /api/words/{}", id);

        // TODO: 从数据库查询单词详情
        Word word = mockWords.stream()
                .filter(w -> w.getId().equals(id))
                .findFirst()
                .orElse(null);

        if (word == null) {
            return ApiResponse.error(404, "单词不存在");
        }

        return ApiResponse.success(word);
    }
}
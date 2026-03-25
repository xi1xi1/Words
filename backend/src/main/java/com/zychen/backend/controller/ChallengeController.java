package com.zychen.backend.controller;

import com.zychen.backend.dto.request.ChallengeStartRequest;
import com.zychen.backend.dto.request.ChallengeSubmitRequest;
import com.zychen.backend.dto.response.ApiResponse;
import com.zychen.backend.dto.response.ChallengeQuestion;
import com.zychen.backend.dto.response.ChallengeStartResponse;
import com.zychen.backend.dto.response.ChallengeSubmitResponse;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@Slf4j
@RestController
@RequestMapping("/api/challenge")
@CrossOrigin(origins = "*")
public class ChallengeController {

    // Mock 题目数据
    private final List<ChallengeQuestion> mockQuestions = Arrays.asList(
            createQuestion(1L, "abandon", List.of("放弃", "保留", "继续", "开始"), 0),
            createQuestion(2L, "ability", List.of("能力", "弱点", "优势", "机会"), 0),
            createQuestion(3L, "absent", List.of("缺席的", "在场的", "丰富的", "稀少的"), 0),
            createQuestion(4L, "abundant", List.of("丰富的", "缺乏的", "普通的", "罕见的"), 0)
    );

    private ChallengeQuestion createQuestion(Long id, String word, List<String> options, Integer correctIndex) {
        ChallengeQuestion q = new ChallengeQuestion();
        q.setId(id);
        q.setWord(word);
        q.setOptions(options);
        q.setCorrectIndex(correctIndex);
        return q;
    }

    /**
     * 开始闯关
     * POST /api/challenge/start
     */
    @PostMapping("/start")
    public ApiResponse<ChallengeStartResponse> startChallenge(
            @Valid @RequestBody ChallengeStartRequest request,
            @RequestHeader(value = "Authorization", required = false) String auth) {
        log.info("POST /api/challenge/start - levelType: {}", request.getLevelType());

        // TODO: 根据关卡等级生成题目
        // 根据等级返回不同数量的题目和限时
        int questionCount = 5;  // 初级5题，中级10题，高级15题
        int timeLimit = 60;      // 初级60秒，中级90秒，高级120秒

        // 取前 questionCount 个题目
        List<ChallengeQuestion> questions = mockQuestions.stream()
                .limit(questionCount)
                .toList();

        ChallengeStartResponse response = new ChallengeStartResponse();
        response.setChallengeId("ch_" + System.currentTimeMillis());
        response.setQuestions(questions);
        response.setTimeLimit(timeLimit);

        return ApiResponse.success(response);
    }

    /**
     * 提交闯关结果
     * POST /api/challenge/submit
     */
    @PostMapping("/submit")
    public ApiResponse<ChallengeSubmitResponse> submitChallenge(
            @Valid @RequestBody ChallengeSubmitRequest request,
            @RequestHeader(value = "Authorization", required = false) String auth) {
        log.info("POST /api/challenge/submit - challengeId: {}, answers: {}",
                request.getChallengeId(), request.getAnswers().size());

        // TODO: 计算得分，更新用户积分
        // 模拟计算得分
        int totalCount = request.getAnswers().size();
        int correctCount = (int) request.getAnswers().stream()
                .filter(a -> a.getSelectedIndex() == 0) // 假设正确答案都是索引0
                .count();
        double accuracy = (double) correctCount / totalCount;
        int score = (int) (accuracy * 1000);  // 根据正确率计算得分
        int addedScore = (int) (score * 0.1); // 增加积分
        int totalScore = 1250 + addedScore;   // 假设原来1250分

        ChallengeSubmitResponse response = new ChallengeSubmitResponse();
        response.setScore(score);
        response.setCorrectCount(correctCount);
        response.setTotalCount(totalCount);
        response.setAccuracy(accuracy);
        response.setAddedScore(addedScore);
        response.setTotalScore(totalScore);

        return ApiResponse.success(response);
    }

    /**
     * 获取闯关记录
     * GET /api/challenge/records
     */
    @GetMapping("/records")
    public ApiResponse<Map<String, Object>> getChallengeRecords(
            @RequestParam(required = false) Integer levelType,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestHeader(value = "Authorization", required = false) String auth) {
        log.info("GET /api/challenge/records - levelType: {}, page: {}, size: {}", levelType, page, size);

        // TODO: 从数据库查询闯关记录
        List<Map<String, Object>> mockRecords = Arrays.asList(
                createRecord(5001L, 1, "初级场", 850, 18, 20, 0.9, "2026-03-18 15:30:00", 375),
                createRecord(5000L, 1, "初级场", 720, 17, 20, 0.85, "2026-03-18 10:20:00", 360),
                createRecord(5002L, 2, "中级场", 920, 22, 25, 0.88, "2026-03-17 14:15:00", 480)
        );

        // 按等级过滤
        if (levelType != null) {
            mockRecords = mockRecords.stream()
                    .filter(r -> r.get("levelType").equals(levelType))
                    .toList();
        }

        Map<String, Object> result = new HashMap<>();
        result.put("content", mockRecords);
        result.put("total", mockRecords.size());
        result.put("page", page);
        result.put("size", size);

        return ApiResponse.success(result);
    }

    private Map<String, Object> createRecord(Long id, Integer levelType, String levelName,
                                             Integer score, Integer correctCount, Integer totalCount,
                                             Double correctRate, String createTime, Integer duration) {
        Map<String, Object> record = new HashMap<>();
        record.put("id", id);
        record.put("levelType", levelType);
        record.put("levelName", levelName);
        record.put("score", score);
        record.put("correctCount", correctCount);
        record.put("totalCount", totalCount);
        record.put("correctRate", correctRate);
        record.put("createTime", createTime);
        record.put("duration", duration);
        return record;
    }
}
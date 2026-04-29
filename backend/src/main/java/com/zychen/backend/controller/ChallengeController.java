package com.zychen.backend.controller;

import com.zychen.backend.dto.request.ChallengeStartRequest;
import com.zychen.backend.dto.request.ChallengeSubmitRequest;
import com.zychen.backend.dto.response.ApiResponse;
import com.zychen.backend.dto.response.ChallengeRecordsPage;
import com.zychen.backend.dto.response.ChallengeStartResponse;
import com.zychen.backend.dto.response.ChallengeSubmitResponse;
import com.zychen.backend.service.ChallengeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

/**
 * 闯关接口。路径与响应结构与 {@code docs/api.yaml} 中 {@code /challenge/*} 一致（servers 已含 {@code /api} 前缀）。
 */
@Slf4j
@RestController
@RequestMapping("/api/challenge")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class ChallengeController {

    private final ChallengeService challengeService;

    /**
     * 开始闯关 — operationId: {@code startChallenge}
     */
    @PostMapping("/start")
    public ApiResponse<ChallengeStartResponse> startChallenge(
            @RequestAttribute("userId") Long userId,
            @Valid @RequestBody ChallengeStartRequest request) {
        log.info("POST /api/challenge/start - levelType: {}", request.getLevelType());
        ChallengeStartResponse response = challengeService.startChallenge(userId, request.getLevelType());
        return ApiResponse.success(response);
    }

    /**
     * 提交闯关结果 — operationId: {@code submitChallenge}
     */
    @PostMapping("/submit")
    public ApiResponse<ChallengeSubmitResponse> submitChallenge(
            @RequestAttribute("userId") Long userId,
            @Valid @RequestBody ChallengeSubmitRequest request) {
        int answerCount = request.getAnswers() == null ? 0 : request.getAnswers().size();
        log.info("POST /api/challenge/submit - challengeId: {}, levelType: {}, answers: {}",
                request.getChallengeId(), request.getLevelType(), answerCount);
        ChallengeSubmitResponse response = challengeService.submitChallenge(userId, request);
        return ApiResponse.success(response);
    }

    /**
     * 获取闯关记录 — operationId: {@code getChallengeRecords}；{@code data} 为分页结构（content、total、page、size）
     */
    @GetMapping("/records")
    public ApiResponse<ChallengeRecordsPage> getChallengeRecords(
            @RequestAttribute("userId") Long userId,
            @RequestParam(required = false) Integer levelType,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("GET /api/challenge/records - levelType: {}, page: {}, size: {}", levelType, page, size);
        ChallengeRecordsPage result = challengeService.getUserHistory(userId, levelType, page, size);
        return ApiResponse.success(result);
    }
}

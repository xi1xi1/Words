package com.zychen.backend.controller;

import com.zychen.backend.dto.response.ApiResponse;
import com.zychen.backend.dto.response.LeaderboardOverview;
import com.zychen.backend.service.LeaderboardService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/leaderboard")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class LeaderboardController {

    private final LeaderboardService leaderboardService;

    /**
     * 获取排行榜
     * GET /api/leaderboard?type=total|daily|weekly&limit=50
     */
    @GetMapping
    public ApiResponse<LeaderboardOverview> getLeaderboard(
            @RequestAttribute("userId") Long userId,
            @RequestParam(defaultValue = "total") String type,
            @RequestParam(defaultValue = "50") int limit) {
        log.info("GET /api/leaderboard - type: {}, limit: {}", type, limit);
        LeaderboardOverview data = leaderboardService.getLeaderboard(userId, type, limit);
        return ApiResponse.success(data);
    }
}

package com.zychen.backend.controller;

import com.zychen.backend.dto.response.ApiResponse;
import com.zychen.backend.dto.response.RankItem;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@Slf4j
@RestController
@RequestMapping("/api/leaderboard")
@CrossOrigin(origins = "*")
public class LeaderboardController {

    /**
     * 获取排行榜
     * GET /api/leaderboard
     */
    @GetMapping
    public ApiResponse<Map<String, Object>> getLeaderboard(
            @RequestParam(defaultValue = "total") String type,
            @RequestParam(defaultValue = "50") int limit,
            @RequestHeader(value = "Authorization", required = false) String auth) {
        log.info("GET /api/leaderboard - type: {}, limit: {}", type, limit);

        // TODO: 从数据库查询排行榜数据
        List<RankItem> mockList = createMockRankList(limit);

        // 模拟当前用户排名（假设用户ID=1001，排名第128）
        Integer myRank = 128;

        Map<String, Object> response = new HashMap<>();
        response.put("list", mockList);
        response.put("myRank", myRank);

        return ApiResponse.success(response);
    }

    /**
     * 创建 Mock 排行榜数据
     */
    private List<RankItem> createMockRankList(int limit) {
        List<RankItem> list = new ArrayList<>();
        for (int i = 1; i <= Math.min(limit, 100); i++) {
            RankItem item = new RankItem();
            item.setRank(i);
            item.setUserId(1000L + i);
            item.setUsername("用户" + i);
            item.setAvatar(i <= 3 ? "https://cdn.beileme.com/avatars/" + i + ".jpg" : null);
            item.setTotalScore(100000 - i * 500);
            list.add(item);
        }
        return list;
    }
}
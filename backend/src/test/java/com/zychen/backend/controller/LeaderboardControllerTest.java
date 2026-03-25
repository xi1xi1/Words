package com.zychen.backend.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
public class LeaderboardControllerTest {

    @Autowired
    private MockMvc mockMvc;

    /**
     * 测试1：获取排行榜成功（默认参数）
     */
    @Test
    void getLeaderboard_success_default() throws Exception {
        mockMvc.perform(get("/api/leaderboard")
                        .header("Authorization", "Bearer mock-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.list").exists())
                .andExpect(jsonPath("$.data.myRank").exists());
    }

    /**
     * 测试2：获取排行榜 - 指定类型和数量
     */
    @Test
    void getLeaderboard_with_type_and_limit() throws Exception {
        mockMvc.perform(get("/api/leaderboard")
                        .param("type", "total")
                        .param("limit", "10")
                        .header("Authorization", "Bearer mock-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.list.length()").value(10));
    }

    /**
     * 测试3：获取排行榜 - 最大限制
     */
    @Test
    void getLeaderboard_max_limit() throws Exception {
        mockMvc.perform(get("/api/leaderboard")
                        .param("limit", "100")
                        .header("Authorization", "Bearer mock-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.list.length()").value(100));
    }

    /**
     * 测试4：获取排行榜 - 超出最大限制（应该限制在100）
     */
    @Test
    void getLeaderboard_limit_exceeds_max() throws Exception {
        mockMvc.perform(get("/api/leaderboard")
                        .param("limit", "200")
                        .header("Authorization", "Bearer mock-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.list.length()").value(100));
    }

    /**
     * 测试5：获取排行榜 - 返回数据格式正确
     */
    @Test
    void getLeaderboard_response_format() throws Exception {
        mockMvc.perform(get("/api/leaderboard")
                        .header("Authorization", "Bearer mock-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].rank").exists())
                .andExpect(jsonPath("$.data.list[0].userId").exists())
                .andExpect(jsonPath("$.data.list[0].username").exists())
                .andExpect(jsonPath("$.data.list[0].totalScore").exists());
    }
}
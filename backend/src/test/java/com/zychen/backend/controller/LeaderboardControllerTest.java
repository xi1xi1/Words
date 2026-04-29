package com.zychen.backend.controller;

import com.zychen.backend.config.JwtUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.jdbc.Sql;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.greaterThan;
import static org.hamcrest.Matchers.lessThanOrEqualTo;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Sql(scripts = "/sql/challenge-test-data.sql", executionPhase = Sql.ExecutionPhase.BEFORE_TEST_CLASS)
public class LeaderboardControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtUtil jwtUtil;

    private String bearerToken;

    @BeforeEach
    void setUp() {
        bearerToken = "Bearer " + jwtUtil.generateToken(1L, "jwt_challenge_user");
    }

    /**
     * 测试1：获取排行榜成功（默认参数）
     */
    @Test
    void getLeaderboard_success_default() throws Exception {
        mockMvc.perform(get("/api/leaderboard")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("success"))
                .andExpect(jsonPath("$.data.list").isArray())
                .andExpect(jsonPath("$.data.list.length()", greaterThan(0)))
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
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.list.length()", lessThanOrEqualTo(10)))
                .andExpect(jsonPath("$.data.list.length()", greaterThan(0)));
    }

    /**
     * 测试3：获取排行榜 - 最大限制
     */
    @Test
    void getLeaderboard_max_limit() throws Exception {
        mockMvc.perform(get("/api/leaderboard")
                        .param("limit", "100")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.list.length()", lessThanOrEqualTo(100)))
                .andExpect(jsonPath("$.data.list.length()", greaterThan(0)));
    }

    /**
     * 测试4：获取排行榜 - 超出最大限制（应该限制在100）
     */
    @Test
    void getLeaderboard_limit_exceeds_max() throws Exception {
        mockMvc.perform(get("/api/leaderboard")
                        .param("limit", "200")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.list.length()", lessThanOrEqualTo(100)))
                .andExpect(jsonPath("$.data.list.length()", greaterThan(0)));
    }

    /**
     * 测试5：获取排行榜 - 返回数据格式正确
     */
    @Test
    void getLeaderboard_response_format() throws Exception {
        mockMvc.perform(get("/api/leaderboard")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list.length()", greaterThan(0)))
                .andExpect(jsonPath("$.data.list[0].rank").exists())
                .andExpect(jsonPath("$.data.list[0].userId").exists())
                .andExpect(jsonPath("$.data.list[0].username").exists())
                .andExpect(jsonPath("$.data.list[0].totalScore").exists());
    }

    @Test
    void getLeaderboard_invalidType_returns400Body() throws Exception {
        mockMvc.perform(get("/api/leaderboard")
                        .param("type", "invalid")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(400))
                .andExpect(jsonPath("$.message").value("不支持的排行榜类型，可选：total、daily、weekly"));
    }
}
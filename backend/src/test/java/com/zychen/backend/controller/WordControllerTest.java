package com.zychen.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zychen.backend.config.JwtUtil;
import com.zychen.backend.dto.request.LearnRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.jdbc.Sql;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Sql(scripts = "/sql/challenge-test-data.sql", executionPhase = Sql.ExecutionPhase.BEFORE_TEST_CLASS)
public class WordControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JwtUtil jwtUtil;

    private String bearerToken;

    @BeforeEach
    void setUp() {
        bearerToken = "Bearer " + jwtUtil.generateToken(1L, "jwt_challenge_user");
    }

    /**
     * 测试1：获取今日单词成功
     */
    @Test
    void getDailyWords_success() throws Exception {
        mockMvc.perform(get("/api/words/daily")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("success"))
                .andExpect(jsonPath("$.data.newWords").isArray())
                .andExpect(jsonPath("$.data.reviewWords").isArray())
                .andExpect(jsonPath("$.data.learnableWordCount", greaterThanOrEqualTo(0)))
                .andExpect(jsonPath("$.data.reviewableWordCount", greaterThanOrEqualTo(0)));
    }

    /**
     * 测试2：提交学习结果成功
     */
    @Test
    void submitLearnResult_success() throws Exception {
        LearnRequest request = new LearnRequest();
        request.setWordId(1L);
        request.setIsCorrect(true);
        request.setStage(1);

        mockMvc.perform(post("/api/words/learn")
                        .header("Authorization", bearerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("success"))
                .andExpect(jsonPath("$.data.completedCount").exists())
                .andExpect(jsonPath("$.data.totalCount").exists());
    }

    /**
     * 测试3：提交学习结果失败 - 缺少参数
     */
    @Test
    void submitLearnResult_failed_missing_params() throws Exception {
        // 只传 wordId，不传 isCorrect
        String request = "{\"wordId\": 1}";

        mockMvc.perform(post("/api/words/learn")
                        .header("Authorization", bearerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(request))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));
    }

    /**
     * 测试4：搜索单词成功
     */
    @Test
    void searchWords_success() throws Exception {
        mockMvc.perform(get("/api/words/search")
                        .param("keyword", "abandon")
                        .param("page", "1")
                        .param("size", "10")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("success"))
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data[0].id").value(1))
                .andExpect(jsonPath("$.data[0].word").value("abandon"));
    }

    /**
     * 测试5：搜索单词 - 默认分页参数
     */
    @Test
    void searchWords_default_pagination() throws Exception {
        mockMvc.perform(get("/api/words/search")
                        .param("keyword", "ab")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data").isArray());
    }

    /**
     * 测试6：获取单词详情成功
     */
    @Test
    void getWordDetail_success() throws Exception {
        mockMvc.perform(get("/api/words/1")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("success"))
                .andExpect(jsonPath("$.data.id").value(1))
                .andExpect(jsonPath("$.data.word").exists())
                .andExpect(jsonPath("$.data.meaning").isArray());
    }

    /**
     * 测试7：获取单词详情 - 单词不存在
     */
    @Test
    void getWordDetail_notFound() throws Exception {
        mockMvc.perform(get("/api/words/999")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(404))
                .andExpect(jsonPath("$.message").value("单词不存在"));
    }

    /**
     * 未携带 Token：拦截器返回 HTTP 401，body.code 与 HTTP 状态一致（与 CLAUDE 约定一致）
     */
    @Test
    void getDailyWords_unauthorized() throws Exception {
        mockMvc.perform(get("/api/words/daily"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));
    }
}
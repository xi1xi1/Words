package com.zychen.backend.controller;

import com.zychen.backend.config.JwtUtil;
import com.zychen.backend.service.AIService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.jdbc.Sql;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.doNothing;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Sql(scripts = "/sql/challenge-test-data.sql", executionPhase = Sql.ExecutionPhase.BEFORE_TEST_CLASS)
public class WordbookControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtUtil jwtUtil;

    @MockBean
    private AIService aiService;

    private String bearerToken;

    @BeforeEach
    void setUp() {
        bearerToken = "Bearer " + jwtUtil.generateToken(1L, "jwt_challenge_user");
        doNothing().when(aiService).generateAndPersistExample(anyLong(), anyString(), nullable(String.class));
    }

    /**
     * 测试1：获取生词本列表成功
     */
    @Test
    void getWordbookList_success() throws Exception {
        mockMvc.perform(get("/api/wordbook/list")
                        .param("page", "1")
                        .param("size", "10")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("success"))
                .andExpect(jsonPath("$.data.content").isArray())
                .andExpect(jsonPath("$.data.total").exists())
                .andExpect(jsonPath("$.data.page").value(1))
                .andExpect(jsonPath("$.data.size").value(10));
    }

    /**
     * 测试2：获取生词本列表 - 默认分页参数
     */
    @Test
    void getWordbookList_default_pagination() throws Exception {
        mockMvc.perform(get("/api/wordbook/list")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("success"))
                .andExpect(jsonPath("$.data.page").value(1))
                .andExpect(jsonPath("$.data.size").value(20));
    }

    /**
     * 测试3：添加单词到生词本成功
     */
    @Test
    void addToWordbook_success() throws Exception {
        mockMvc.perform(post("/api/wordbook/add/1")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("已加入生词本"));
    }

    /**
     * 测试4：添加单词失败 - wordId 非数字
     */
    @Test
    void addToWordbook_failed_invalid_wordId() throws Exception {
        mockMvc.perform(post("/api/wordbook/add/abc")
                        .header("Authorization", bearerToken))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));
    }

    /**
     * 测试5：从生词本移除成功
     */
    @Test
    void removeFromWordbook_success() throws Exception {
        mockMvc.perform(delete("/api/wordbook/remove/1")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("已移除"));
    }

    /**
     * 测试6：获取AI生成内容成功
     */
    @Test
    void getAIContent_success() throws Exception {
        mockMvc.perform(get("/api/wordbook/ai/1")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("success"))
                .andExpect(jsonPath("$.data.word").exists())
                .andExpect(jsonPath("$.data.examples").isArray())
                .andExpect(jsonPath("$.data.dialogues").isArray());
    }

    @Test
    void getWordbookList_unauthorized() throws Exception {
        mockMvc.perform(get("/api/wordbook/list"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));
    }
}
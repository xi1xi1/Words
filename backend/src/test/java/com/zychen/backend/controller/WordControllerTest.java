package com.zychen.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zychen.backend.dto.request.LearnRequest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
public class WordControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    /**
     * 测试1：获取今日单词成功
     */
    @Test
    void getDailyWords_success() throws Exception {
        mockMvc.perform(get("/api/words/daily")
                        .header("Authorization", "Bearer mock-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.newWords").exists())
                .andExpect(jsonPath("$.data.reviewWords").exists());
    }

    /**
     * 测试2：提交学习结果成功
     */
    @Test
    void submitLearnResult_success() throws Exception {
        LearnRequest request = new LearnRequest();
        request.setWordId(1L);
        request.setIsCorrect(true);

        mockMvc.perform(post("/api/words/learn")
                        .header("Authorization", "Bearer mock-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.nextWord").exists())
                .andExpect(jsonPath("$.data.progress").exists());
    }

    /**
     * 测试3：提交学习结果失败 - 缺少参数
     */
    @Test
    void submitLearnResult_failed_missing_params() throws Exception {
        // 只传 wordId，不传 isCorrect
        String request = "{\"wordId\": 1}";

        mockMvc.perform(post("/api/words/learn")
                        .header("Authorization", "Bearer mock-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(request))
                .andExpect(status().isBadRequest());
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
                        .header("Authorization", "Bearer mock-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.content").exists())
                .andExpect(jsonPath("$.data.total").exists());
    }

    /**
     * 测试5：搜索单词 - 默认分页参数
     */
    @Test
    void searchWords_default_pagination() throws Exception {
        mockMvc.perform(get("/api/words/search")
                        .param("keyword", "test")
                        .header("Authorization", "Bearer mock-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.page").value(1))
                .andExpect(jsonPath("$.data.size").value(20));
    }

    /**
     * 测试6：获取单词详情成功
     */
    @Test
    void getWordDetail_success() throws Exception {
        mockMvc.perform(get("/api/words/1")
                        .header("Authorization", "Bearer mock-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.id").value(1))
                .andExpect(jsonPath("$.data.word").exists())
                .andExpect(jsonPath("$.data.meaning").exists());
    }

    /**
     * 测试7：获取单词详情 - 单词不存在
     */
    @Test
    void getWordDetail_notFound() throws Exception {
        mockMvc.perform(get("/api/words/999")
                        .header("Authorization", "Bearer mock-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(404))
                .andExpect(jsonPath("$.message").value("单词不存在"));
    }
}
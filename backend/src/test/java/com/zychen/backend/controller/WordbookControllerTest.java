package com.zychen.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zychen.backend.dto.request.AddToWordbookRequest;
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
public class WordbookControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    /**
     * 测试1：获取生词本列表成功
     */
    @Test
    void getWordbookList_success() throws Exception {
        mockMvc.perform(get("/api/wordbook/list")
                        .param("page", "1")
                        .param("size", "10")
                        .header("Authorization", "Bearer mock-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.content").exists())
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
                        .header("Authorization", "Bearer mock-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.page").value(1))
                .andExpect(jsonPath("$.data.size").value(20));
    }

    /**
     * 测试3：添加单词到生词本成功
     */
    @Test
    void addToWordbook_success() throws Exception {
        AddToWordbookRequest request = new AddToWordbookRequest();
        request.setWordId(1L);

        mockMvc.perform(post("/api/wordbook/add")
                        .header("Authorization", "Bearer mock-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("已加入生词本"));
    }

    /**
     * 测试4：添加单词失败 - 缺少 wordId
     */
    @Test
    void addToWordbook_failed_missing_wordId() throws Exception {
        String request = "{}";  // 空对象

        mockMvc.perform(post("/api/wordbook/add")
                        .header("Authorization", "Bearer mock-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(request))
                .andExpect(status().isBadRequest());
    }

    /**
     * 测试5：从生词本移除成功
     */
    @Test
    void removeFromWordbook_success() throws Exception {
        mockMvc.perform(delete("/api/wordbook/remove/1")
                        .header("Authorization", "Bearer mock-token"))
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
                        .header("Authorization", "Bearer mock-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.word").exists())
                .andExpect(jsonPath("$.data.examples").exists())
                .andExpect(jsonPath("$.data.dialogues").exists());
    }
}
package com.zychen.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.HashMap;
import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
public class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    /**
     * 测试1：获取用户信息成功
     */
    @Test
    void getProfile_success() throws Exception {
        mockMvc.perform(get("/api/user/profile")
                        .header("Authorization", "Bearer mock-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.id").exists())
                .andExpect(jsonPath("$.data.username").exists())
                .andExpect(jsonPath("$.data.totalScore").exists())
                .andExpect(jsonPath("$.data.level").exists());
    }

    /**
     * 测试2：更新头像成功
     */
    @Test
    void updateProfile_success() throws Exception {
        Map<String, String> request = new HashMap<>();
        request.put("avatar", "https://cdn.beileme.com/avatars/new.jpg");

        mockMvc.perform(put("/api/user/profile")
                        .header("Authorization", "Bearer mock-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("更新成功"));
    }

    /**
     * 测试3：修改密码成功
     */
    @Test
    void changePassword_success() throws Exception {
        Map<String, String> request = new HashMap<>();
        request.put("oldPassword", "123456");
        request.put("newPassword", "654321");

        mockMvc.perform(put("/api/user/password")
                        .header("Authorization", "Bearer mock-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("密码修改成功"));
    }

    /**
     * 测试4：修改密码失败 - 缺少参数
     */
    @Test
    void changePassword_failed_missing_params() throws Exception {
        Map<String, String> request = new HashMap<>();
        request.put("oldPassword", "123456");
        // 缺少 newPassword

        mockMvc.perform(put("/api/user/password")
                        .header("Authorization", "Bearer mock-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }
}
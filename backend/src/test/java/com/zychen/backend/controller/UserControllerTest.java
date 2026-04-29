package com.zychen.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zychen.backend.config.JwtUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.jdbc.Sql;
import org.springframework.test.web.servlet.MockMvc;

import java.util.HashMap;
import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Sql(scripts = "/sql/challenge-test-data.sql", executionPhase = Sql.ExecutionPhase.BEFORE_TEST_CLASS)
public class UserControllerTest {

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
     * 测试1：获取用户信息成功
     */
    @Test
    void getProfile_success() throws Exception {
        mockMvc.perform(get("/api/user/profile")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("success"))
                .andExpect(jsonPath("$.data.id").exists())
                .andExpect(jsonPath("$.data.username").value("jwt_challenge_user"))
                .andExpect(jsonPath("$.data.totalScore").exists())
                .andExpect(jsonPath("$.data.level").exists());
    }

    @Test
    void getProfile_unauthorized() throws Exception {
        mockMvc.perform(get("/api/user/profile"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));
    }

    /**
     * 测试2：更新头像成功
     */
    @Test
    void updateProfile_success() throws Exception {
        Map<String, String> request = new HashMap<>();
        request.put("avatar", "https://cdn.beileme.com/avatars/new.jpg");

        mockMvc.perform(put("/api/user/profile")
                        .header("Authorization", bearerToken)
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
        request.put("oldPassword", "password");
        request.put("newPassword", "654321");

        mockMvc.perform(put("/api/user/password")
                        .header("Authorization", bearerToken)
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
        request.put("oldPassword", "password");
        // 缺少 newPassword

        mockMvc.perform(put("/api/user/password")
                        .header("Authorization", bearerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }
}
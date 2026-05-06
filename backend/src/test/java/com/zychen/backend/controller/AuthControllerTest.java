package com.zychen.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zychen.backend.config.JwtUtil;
import com.zychen.backend.dto.request.LoginRequest;
import com.zychen.backend.dto.request.RegisterRequest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.UUID;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
public class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JwtUtil jwtUtil;

    /**
     * 测试1：注册成功
     */
    @Test
    void register_success() throws Exception {
        RegisterRequest request = new RegisterRequest();
        request.setUsername("u_" + UUID.randomUUID().toString().substring(0, 8));
        request.setPassword("Testpass1");
        request.setEmail("test-" + UUID.randomUUID() + "@example.com");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("注册成功"))
                .andExpect(jsonPath("$.data.token").exists())
                .andExpect(jsonPath("$.data.userInfo.username").value(request.getUsername()));
    }

    /**
     * 测试2：注册失败 - 用户名已存在
     */
    @Test
    void register_failed_username_exists() throws Exception {
        // 先注册一个用户
        RegisterRequest request1 = new RegisterRequest();
        request1.setUsername("existinguser");
        request1.setPassword("Testpass1");
        request1.setEmail("existing@example.com");

        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request1)));

        // 再用相同用户名注册
        RegisterRequest request2 = new RegisterRequest();
        request2.setUsername("existinguser");
        request2.setPassword("Testpass1");
        request2.setEmail("another@example.com");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request2)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(400))
                .andExpect(jsonPath("$.message").value("用户名已存在"));
    }

    /**
     * 测试3：注册失败 - 用户名太短
     */
    @Test
    void register_failed_username_too_short() throws Exception {
        RegisterRequest request = new RegisterRequest();
        request.setUsername("ab");  // 只有2位
        request.setPassword("Testpass1");
        request.setEmail("test@example.com");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    /**
     * 测试4：登录成功
     */
    @Test
    void login_success() throws Exception {
        String username = "login_ok_" + UUID.randomUUID().toString().substring(0, 8);
        // 先注册一个用户（随机用户名，避免库中旧账号密码与本次不一致）
        RegisterRequest registerRequest = new RegisterRequest();
        registerRequest.setUsername(username);
        registerRequest.setPassword("Testpass1");
        registerRequest.setEmail("login-" + UUID.randomUUID() + "@example.com");

        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(registerRequest)));

        // 登录
        LoginRequest loginRequest = new LoginRequest();
        loginRequest.setUsername(username);
        loginRequest.setPassword("Testpass1");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("登录成功"))
                .andExpect(jsonPath("$.data.token").exists())
                .andExpect(jsonPath("$.data.userInfo.username").value(username));
    }

    /**
     * 测试5：登录失败 - 密码错误
     */
    @Test
    void login_failed_wrong_password() throws Exception {
        // 先注册一个用户
        RegisterRequest registerRequest = new RegisterRequest();
        registerRequest.setUsername("wrongpwduser");
        registerRequest.setPassword("Testpass1");
        registerRequest.setEmail("wrongpwd@example.com");

        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(registerRequest)));

        // 用错误密码登录
        LoginRequest loginRequest = new LoginRequest();
        loginRequest.setUsername("wrongpwduser");
        loginRequest.setPassword("wrongpassword");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(401))
                .andExpect(jsonPath("$.message").value("用户名或密码错误"));
    }

    /**
     * 测试6：登录失败 - 用户不存在
     */
    @Test
    void login_failed_user_not_exists() throws Exception {
        LoginRequest loginRequest = new LoginRequest();
        loginRequest.setUsername("notexists");
        loginRequest.setPassword("123456");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(401))
                .andExpect(jsonPath("$.message").value("用户名或密码错误"));
    }

    /**
     * 测试7：登出成功
     */
    @Test
    void logout_success() throws Exception {
        // 使用独立 subject，避免与闯关等测试共用 (1L, jwt_challenge_user) 时在秒级 iat 下 token 撞车进黑名单
        String token = jwtUtil.generateToken(999999L, "logout_test_only");

        mockMvc.perform(post("/api/auth/logout")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("退出成功"));
    }
}
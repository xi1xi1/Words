package com.zychen.backend.controller;

import com.zychen.backend.dto.request.LoginRequest;
import com.zychen.backend.dto.request.RegisterRequest;
import com.zychen.backend.dto.response.ApiResponse;
import com.zychen.backend.dto.response.LoginResponse;
import com.zychen.backend.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AuthController {

    private final AuthService authService;

    /**
     * 用户注册
     * POST /api/auth/register
     */
    @PostMapping("/register")
    public ApiResponse<LoginResponse> register(@Valid @RequestBody RegisterRequest request) {
        try {
            LoginResponse response = authService.register(request);
            return ApiResponse.success("注册成功", response);
        } catch (RuntimeException e) {
            log.error("注册失败: {}", e.getMessage());
            return ApiResponse.error(400, e.getMessage());
        }
    }

    /**
     * 用户登录
     * POST /api/auth/login
     */
    @PostMapping("/login")
    public ApiResponse<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        try {
            LoginResponse response = authService.login(request);
            return ApiResponse.success("登录成功", response);
        } catch (RuntimeException e) {
            log.error("登录失败: {}", e.getMessage());
            return ApiResponse.error(401, e.getMessage());
        }
    }

    /**
     * 用户登出
     * POST /api/auth/logout
     */
    @PostMapping("/logout")
    public ApiResponse<Void> logout(HttpServletRequest request) {
        String token = extractToken(request);
        if (token != null) {
            authService.logout(token);
            log.info("用户登出成功");
        }
        return ApiResponse.success("退出成功", null);
    }

    /**
     * 从请求头中提取Token
     */
    private String extractToken(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}
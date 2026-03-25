package com.zychen.backend.service;

import com.zychen.backend.dto.request.LoginRequest;
import com.zychen.backend.dto.request.RegisterRequest;
import com.zychen.backend.dto.response.LoginResponse;

public interface AuthService {

    /**
     * 用户注册
     * @param request 注册请求（用户名、密码、邮箱）
     * @return 登录响应（Token + 用户信息）
     */
    LoginResponse register(RegisterRequest request);

    /**
     * 用户登录
     * @param request 登录请求（用户名、密码）
     * @return 登录响应（Token + 用户信息）
     */
    LoginResponse login(LoginRequest request);

    /**
     * 用户登出
     * @param token 用户Token
     */
    void logout(String token);

    /**
     * 验证Token是否有效
     * @param token 用户Token
     * @return true-有效 false-无效
     */
    boolean validateToken(String token);

    /**
     * 从Token中获取用户ID
     * @param token 用户Token
     * @return 用户ID
     */
    Long getUserIdFromToken(String token);
}
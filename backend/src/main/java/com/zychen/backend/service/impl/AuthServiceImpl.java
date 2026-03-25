package com.zychen.backend.service.impl;

import com.zychen.backend.config.JwtUtil;
import com.zychen.backend.dto.request.LoginRequest;
import com.zychen.backend.dto.request.RegisterRequest;
import com.zychen.backend.dto.response.LoginResponse;
import com.zychen.backend.dto.response.UserInfoResponse;
import com.zychen.backend.entity.User;
import com.zychen.backend.mapper.UserMapper;
import com.zychen.backend.service.AuthService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserMapper userMapper;
    private final JwtUtil jwtUtil;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    // Token黑名单（登出用）
    private final Map<String, Boolean> tokenBlacklist = new ConcurrentHashMap<>();

    @Override
    public LoginResponse register(RegisterRequest request) {
        log.info("用户注册: {}", request.getUsername());

        // 1. 检查用户名是否已存在
        User existingUser = userMapper.findByUsername(request.getUsername());
        if (existingUser != null) {
            throw new RuntimeException("用户名已存在");
        }

        // 2. 创建新用户
        User user = new User();
        user.setUsername(request.getUsername());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setEmail(request.getEmail());
        user.setAvatar(null);
        user.setTotalScore(0);
        user.setLevel(1);

        // 3. 保存到数据库
        userMapper.insert(user);

        // 4. 生成Token
        String token = jwtUtil.generateToken(user.getId(), user.getUsername());

        // 5. 返回响应
        UserInfoResponse userInfo = new UserInfoResponse(
                user.getId(),
                user.getUsername(),
                user.getAvatar(),
                user.getTotalScore(),
                user.getLevel(),
                user.getCreateTime()
        );

        return new LoginResponse(token, userInfo);
    }

    @Override
    public LoginResponse login(LoginRequest request) {
        log.info("用户登录: {}", request.getUsername());

        // 1. 查找用户
        User user = userMapper.findByUsername(request.getUsername());
        if (user == null) {
            throw new RuntimeException("用户名或密码错误");
        }

        // 2. 验证密码
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("用户名或密码错误");
        }

        // 3. 生成Token
        String token = jwtUtil.generateToken(user.getId(), user.getUsername());

        // 4. 返回响应
        UserInfoResponse userInfo = new UserInfoResponse(
                user.getId(),
                user.getUsername(),
                user.getAvatar(),
                user.getTotalScore(),
                user.getLevel(),
                user.getCreateTime()
        );

        return new LoginResponse(token, userInfo);
    }

    @Override
    public void logout(String token) {
        log.info("用户登出");
        tokenBlacklist.put(token, true);
    }

    @Override
    public boolean validateToken(String token) {
        // 检查是否在黑名单中
        if (tokenBlacklist.containsKey(token)) {
            return false;
        }
        return jwtUtil.validateToken(token);
    }

    @Override
    public Long getUserIdFromToken(String token) {
        return jwtUtil.getUserIdFromToken(token);
    }
}
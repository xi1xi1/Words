package com.zychen.backend.controller;

import com.zychen.backend.dto.request.ChangePasswordRequest;
import com.zychen.backend.dto.response.ApiResponse;
import com.zychen.backend.dto.response.UserInfoResponse;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/user")
@CrossOrigin(origins = "*")
public class UserController {

    /**
     * 获取用户信息
     * GET /api/user/profile
     */
    @GetMapping("/profile")
    public ApiResponse<UserInfoResponse> getProfile(
            @RequestHeader(value = "Authorization", required = false) String auth) {
        log.info("GET /api/user/profile");

        // TODO: 从Token获取用户ID，查询数据库
        // 暂时返回Mock数据
        UserInfoResponse mockUser = new UserInfoResponse(
                1001L,
                "zhangsan",
                "https://cdn.beileme.com/avatars/1.jpg",
                1250,
                3,
                LocalDateTime.now()
        );
        return ApiResponse.success(mockUser);
    }

    /**
     * 更新用户信息（头像）
     * PUT /api/user/profile
     */
    @PutMapping("/profile")
    public ApiResponse<Void> updateProfile(
            @RequestBody Map<String, String> request,
            @RequestHeader(value = "Authorization", required = false) String auth) {
        String avatar = request.get("avatar");
        log.info("PUT /api/user/profile - avatar: {}", avatar);

        // TODO: 更新数据库中的用户头像
        // 暂时返回成功
        return ApiResponse.success("更新成功", null);
    }

    /**
     * 修改密码
     * PUT /api/user/password
     */
    @PutMapping("/password")
    public ApiResponse<Void> changePassword(
            @Valid @RequestBody ChangePasswordRequest request,
            @RequestHeader(value = "Authorization", required = false) String auth) {
        log.info("PUT /api/user/password - oldPassword: {}, newPassword: {}",
                request.getOldPassword(), request.getNewPassword());

        // TODO: 验证旧密码，更新新密码
        return ApiResponse.success("密码修改成功", null);
    }
}

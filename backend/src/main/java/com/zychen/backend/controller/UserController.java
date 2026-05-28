package com.zychen.backend.controller;

import com.zychen.backend.dto.request.ChangePasswordRequest;
import com.zychen.backend.dto.response.ApiResponse;
import com.zychen.backend.dto.response.UserInfoResponse;
import com.zychen.backend.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    /**
     * 获取用户信息
     * GET /api/user/profile
     */
    @GetMapping("/profile")
    public ApiResponse<UserInfoResponse> getProfile(@RequestAttribute("userId") Long userId) {
        log.info("GET /api/user/profile");
        UserInfoResponse userInfo = userService.getUserInfo(userId);
        return ApiResponse.success(userInfo);
    }

    /**
     * 更新用户信息（头像）
     * PUT /api/user/profile
     */
    @PutMapping("/profile")
    public ApiResponse<Void> updateProfile(
            @RequestAttribute("userId") Long userId,
            @RequestBody Map<String, String> request) {
        String avatar = request.get("avatar");
        log.info("PUT /api/user/profile - avatar: {}", avatar);
        userService.updateAvatar(userId, avatar);
        return ApiResponse.success("更新成功", null);
    }

    /**
     * 修改密码
     * PUT /api/user/password
     */
    @PutMapping("/password")
    public ApiResponse<Void> changePassword(
            @RequestAttribute("userId") Long userId,
            @Valid @RequestBody ChangePasswordRequest request) {
        log.info("PUT /api/user/password");
        userService.changePassword(userId, request.getOldPassword(), request.getNewPassword());
        return ApiResponse.success("密码修改成功", null);
    }
}

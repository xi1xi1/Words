package com.zychen.backend.service;

import com.zychen.backend.dto.response.UserInfoResponse;

public interface UserService {

    /**
     * 获取用户信息
     * @param userId 用户ID
     * @return 用户信息
     */
    UserInfoResponse getUserInfo(Long userId);

    /**
     * 更新用户头像
     * @param userId 用户ID
     * @param avatar 头像URL
     * @return 是否成功
     */
    boolean updateAvatar(Long userId, String avatar);

    /**
     * 修改密码
     * @param userId 用户ID
     * @param oldPassword 旧密码
     * @param newPassword 新密码
     * @return 是否成功
     */
    boolean changePassword(Long userId, String oldPassword, String newPassword);
}
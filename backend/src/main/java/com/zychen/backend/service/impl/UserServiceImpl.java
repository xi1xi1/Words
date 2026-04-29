package com.zychen.backend.service.impl;

import com.zychen.backend.common.BusinessException;
import com.zychen.backend.dto.response.UserInfoResponse;
import com.zychen.backend.entity.User;
import com.zychen.backend.mapper.UserMapper;
import com.zychen.backend.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserMapper userMapper;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    @Override
    public UserInfoResponse getUserInfo(Long userId) {
        User user = userMapper.findById(userId);
        if (user == null) {
            throw new BusinessException(404, "用户不存在");
        }

        return new UserInfoResponse(
                user.getId(),
                user.getUsername(),
                user.getAvatar(),
                user.getTotalScore(),
                user.getLevel(),
                user.getCreateTime()
        );
    }

    @Override
    @Transactional
    public boolean updateAvatar(Long userId, String avatar) {
        int rows = userMapper.updateAvatar(userId, avatar);
        if (rows == 0) {
            throw new BusinessException(404, "用户不存在");
        }
        log.info("用户 {} 更新头像成功", userId);
        return true;
    }

    @Override
    @Transactional
    public boolean changePassword(Long userId, String oldPassword, String newPassword) {
        User user = userMapper.findById(userId);
        if (user == null) {
            throw new BusinessException(404, "用户不存在");
        }

        if (!passwordEncoder.matches(oldPassword, user.getPassword())) {
            throw new BusinessException(400, "原密码错误");
        }

        String encodedNewPassword = passwordEncoder.encode(newPassword);
        int rows = userMapper.updatePassword(userId, encodedNewPassword);
        if (rows == 0) {
            throw new BusinessException(500, "密码修改失败");
        }

        log.info("用户 {} 修改密码成功", userId);
        return true;
    }
}
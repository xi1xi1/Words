package com.zychen.backend.service.impl;

import com.zychen.backend.config.JwtUtil;
import com.zychen.backend.dto.request.LoginRequest;
import com.zychen.backend.dto.request.RegisterRequest;
import com.zychen.backend.dto.response.LoginResponse;
import com.zychen.backend.entity.User;
import com.zychen.backend.mapper.UserMapper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceImplTest {

    @Mock
    private UserMapper userMapper;

    @Mock
    private JwtUtil jwtUtil;

    @InjectMocks
    private AuthServiceImpl authService;

    @Test
    void register_usernameExists_throws() {
        RegisterRequest req = new RegisterRequest();
        req.setUsername("u1");
        req.setPassword("123456");
        req.setEmail("u1@example.com");
        when(userMapper.findByUsername("u1")).thenReturn(new User());

        RuntimeException ex = assertThrows(RuntimeException.class, () -> authService.register(req));
        assertEquals("用户名已存在", ex.getMessage());
        verify(userMapper, never()).insert(any());
    }

    @Test
    void register_success_insertsUserAndReturnsToken() {
        RegisterRequest req = new RegisterRequest();
        req.setUsername("u2");
        req.setPassword("123456");
        req.setEmail("u2@example.com");

        when(userMapper.findByUsername("u2")).thenReturn(null);
        doAnswer(inv -> {
            User u = inv.getArgument(0);
            u.setId(10L);
            return 1;
        }).when(userMapper).insert(any(User.class));
        when(jwtUtil.generateToken(10L, "u2")).thenReturn("tkn");

        LoginResponse resp = authService.register(req);
        assertEquals("tkn", resp.getToken());
        assertNotNull(resp.getUserInfo());
        assertEquals(10L, resp.getUserInfo().getId());
        assertEquals("u2", resp.getUserInfo().getUsername());
        assertEquals(0, resp.getUserInfo().getTotalScore());
        assertEquals(1, resp.getUserInfo().getLevel());

        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        verify(userMapper).insert(userCaptor.capture());
        User inserted = userCaptor.getValue();
        assertEquals("u2", inserted.getUsername());
        assertEquals("u2@example.com", inserted.getEmail());
        assertNotNull(inserted.getPassword());
        assertNotEquals("123456", inserted.getPassword());
        assertTrue(new BCryptPasswordEncoder().matches("123456", inserted.getPassword()));
    }

    @Test
    void login_userNotFound_throws() {
        LoginRequest req = new LoginRequest();
        req.setUsername("missing");
        req.setPassword("123456");
        when(userMapper.findByUsername("missing")).thenReturn(null);

        RuntimeException ex = assertThrows(RuntimeException.class, () -> authService.login(req));
        assertEquals("用户名或密码错误", ex.getMessage());
    }

    @Test
    void login_wrongPassword_throws() {
        LoginRequest req = new LoginRequest();
        req.setUsername("u");
        req.setPassword("bad");

        User user = new User();
        user.setId(1L);
        user.setUsername("u");
        user.setPassword(new BCryptPasswordEncoder().encode("good"));
        when(userMapper.findByUsername("u")).thenReturn(user);

        RuntimeException ex = assertThrows(RuntimeException.class, () -> authService.login(req));
        assertEquals("用户名或密码错误", ex.getMessage());
    }

    @Test
    void login_success_returnsTokenAndUserInfo() {
        LoginRequest req = new LoginRequest();
        req.setUsername("u");
        req.setPassword("123456");

        User user = new User();
        user.setId(2L);
        user.setUsername("u");
        user.setPassword(new BCryptPasswordEncoder().encode("123456"));
        user.setTotalScore(5);
        user.setLevel(2);
        when(userMapper.findByUsername("u")).thenReturn(user);
        when(jwtUtil.generateToken(2L, "u")).thenReturn("tok");

        LoginResponse resp = authService.login(req);
        assertEquals("tok", resp.getToken());
        assertEquals(2L, resp.getUserInfo().getId());
        assertEquals("u", resp.getUserInfo().getUsername());
        assertEquals(5, resp.getUserInfo().getTotalScore());
        assertEquals(2, resp.getUserInfo().getLevel());
    }

    @Test
    void validateToken_blacklisted_returnsFalseWithoutJwtCheck() {
        authService.logout("badToken");
        assertFalse(authService.validateToken("badToken"));
        verify(jwtUtil, never()).validateToken(eq("badToken"));
    }

    @Test
    void validateToken_notBlacklisted_delegatesToJwt() {
        when(jwtUtil.validateToken("ok")).thenReturn(true);
        assertTrue(authService.validateToken("ok"));
        verify(jwtUtil).validateToken("ok");
    }
}


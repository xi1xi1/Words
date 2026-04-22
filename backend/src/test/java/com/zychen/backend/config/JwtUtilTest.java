package com.zychen.backend.config;

import com.zychen.backend.common.BusinessException;
import jakarta.servlet.http.HttpServletRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;

class JwtUtilTest {

    private JwtUtil jwtUtil;

    @BeforeEach
    void setUp() {
        jwtUtil = new JwtUtil();
        // 32+ chars => >= 256 bits for HS256 key bytes
        ReflectionTestUtils.setField(jwtUtil, "secret", "01234567890123456789012345678901");
        ReflectionTestUtils.setField(jwtUtil, "expiration", 60_000L);
    }

    @Test
    void generateAndParseToken_roundTripUserIdAndUsername() {
        String token = jwtUtil.generateToken(12L, "alice");
        assertNotNull(token);
        assertEquals(12L, jwtUtil.getUserIdFromToken(token));
        assertEquals("alice", jwtUtil.getUsernameFromToken(token));
        assertTrue(jwtUtil.validateToken(token));
    }

    @Test
    void validateToken_invalid_returnsFalse() {
        assertFalse(jwtUtil.validateToken("not-a-jwt"));
    }

    @Test
    void getUserIdFromRequest_prefersAttribute() {
        HttpServletRequest req = Mockito.mock(HttpServletRequest.class);
        when(req.getAttribute("userId")).thenReturn(99L);
        assertEquals(99L, jwtUtil.getUserIdFromRequest(req));
    }

    @Test
    void getUserIdFromRequest_bearerToken_parses() {
        String token = jwtUtil.generateToken(7L, "u");
        HttpServletRequest req = Mockito.mock(HttpServletRequest.class);
        when(req.getAttribute("userId")).thenReturn(null);
        when(req.getHeader("Authorization")).thenReturn("Bearer " + token);
        assertEquals(7L, jwtUtil.getUserIdFromRequest(req));
    }

    @Test
    void getUserIdFromRequest_missing_throws401() {
        HttpServletRequest req = Mockito.mock(HttpServletRequest.class);
        when(req.getAttribute("userId")).thenReturn(null);
        when(req.getHeader("Authorization")).thenReturn(null);

        BusinessException ex = assertThrows(BusinessException.class, () -> jwtUtil.getUserIdFromRequest(req));
        assertEquals(401, ex.getCode());
        assertEquals("未认证", ex.getMessage());
    }
}


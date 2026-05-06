package com.zychen.backend.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zychen.backend.service.AuthService;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class JwtInterceptorTest {

    private final AuthService authService = mock(AuthService.class);
    private final JwtUtil jwtUtil = mock(JwtUtil.class);
    private final JwtInterceptor interceptor = new JwtInterceptor(authService, jwtUtil, new ObjectMapper());

    @Test
    void preHandle_optionsRequest_allowsDirectly() throws Exception {
        MockHttpServletRequest req = new MockHttpServletRequest("OPTIONS", "/api/words/daily");
        MockHttpServletResponse resp = new MockHttpServletResponse();

        assertTrue(interceptor.preHandle(req, resp, new Object()));
    }

    @Test
    void preHandle_missingAuthorization_returns401() throws Exception {
        MockHttpServletRequest req = new MockHttpServletRequest("GET", "/api/words/daily");
        MockHttpServletResponse resp = new MockHttpServletResponse();

        assertFalse(interceptor.preHandle(req, resp, new Object()));
        assertEquals(401, resp.getStatus());
    }

    @Test
    void preHandle_invalidToken_returns401() throws Exception {
        MockHttpServletRequest req = new MockHttpServletRequest("GET", "/api/words/daily");
        req.addHeader("Authorization", "Bearer bad-token");
        MockHttpServletResponse resp = new MockHttpServletResponse();
        when(authService.validateToken("bad-token")).thenReturn(false);

        assertFalse(interceptor.preHandle(req, resp, new Object()));
        assertEquals(401, resp.getStatus());
    }

    @Test
    void preHandle_validToken_setsUserIdAndPasses() throws Exception {
        MockHttpServletRequest req = new MockHttpServletRequest("GET", "/api/words/daily");
        req.addHeader("Authorization", "Bearer good");
        MockHttpServletResponse resp = new MockHttpServletResponse();
        when(authService.validateToken("good")).thenReturn(true);
        when(jwtUtil.getUserIdFromToken("good")).thenReturn(7L);

        assertTrue(interceptor.preHandle(req, resp, new Object()));
        assertEquals(7L, req.getAttribute("userId"));
        verify(jwtUtil).getUserIdFromToken("good");
    }

    @Test
    void preHandle_tokenParseThrows_returns401() throws Exception {
        MockHttpServletRequest req = new MockHttpServletRequest("GET", "/api/words/daily");
        req.addHeader("Authorization", "Bearer x");
        MockHttpServletResponse resp = new MockHttpServletResponse();
        when(authService.validateToken("x")).thenReturn(true);
        when(jwtUtil.getUserIdFromToken("x")).thenThrow(new RuntimeException("boom"));

        assertFalse(interceptor.preHandle(req, resp, new Object()));
        assertEquals(401, resp.getStatus());
    }
}

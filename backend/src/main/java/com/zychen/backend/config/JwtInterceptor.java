package com.zychen.backend.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zychen.backend.dto.response.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.nio.charset.StandardCharsets;

/**
 * JWT 校验：解析 {@code Authorization: Bearer &lt;token&gt;}，将 {@code userId} 写入 request 属性。
 * <p>
 * 登录、注册等 {@code /api/auth/**} 由 {@link WebConfig} 排除，不进入本拦截器。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class JwtInterceptor implements HandlerInterceptor {

    private final JwtUtil jwtUtil;
    private final ObjectMapper objectMapper;

    @Override
    public boolean preHandle(@NonNull HttpServletRequest request,
                             @NonNull HttpServletResponse response,
                             @NonNull Object handler) throws Exception {
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return true;
        }

        String auth = request.getHeader("Authorization");
        if (auth == null || !auth.startsWith("Bearer ")) {
            writeJson(response, HttpServletResponse.SC_UNAUTHORIZED, "未认证");
            return false;
        }

        String token = auth.substring(7).trim();
        if (token.isEmpty() || !jwtUtil.validateToken(token)) {
            writeJson(response, HttpServletResponse.SC_UNAUTHORIZED, "Token无效或已过期");
            return false;
        }

        try {
            Long userId = jwtUtil.getUserIdFromToken(token);
            request.setAttribute("userId", userId);
            return true;
        } catch (Exception e) {
            log.warn("解析 userId 失败: {}", e.getMessage());
            writeJson(response, HttpServletResponse.SC_UNAUTHORIZED, "Token无效");
            return false;
        }
    }

    private void writeJson(HttpServletResponse response, int httpStatus, String message) throws Exception {
        response.setStatus(httpStatus);
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        ApiResponse<Void> body = ApiResponse.error(httpStatus, message);
        objectMapper.writeValue(response.getWriter(), body);
    }
}

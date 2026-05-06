package com.zychen.backend.config;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.util.StringUtils;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.Arrays;

/**
 * 注册 JWT 拦截器：保护 {@code /api/**}；仅放行登录、注册。
 * {@code POST /api/auth/logout} 需携带 Bearer Token。
 * <p>
 * CORS 白名单见 {@code app.cors.allowed-origins}，替代各 Controller 上的 {@code origins = "*"}。
 */
@Configuration
@RequiredArgsConstructor
public class WebConfig implements WebMvcConfigurer {

    private final JwtInterceptor jwtInterceptor;

    @Value("${app.cors.allowed-origins}")
    private String corsAllowedOrigins;

    private String[] corsOriginArray;

    @PostConstruct
    void parseCorsOrigins() {
        corsOriginArray = Arrays.stream(corsAllowedOrigins.split(","))
                .map(String::trim)
                .filter(StringUtils::hasText)
                .toArray(String[]::new);
        if (corsOriginArray.length == 0) {
            throw new IllegalStateException("app.cors.allowed-origins 不能为空，请配置允许的前端 Origin（逗号分隔）");
        }
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins(corsOriginArray)
                .allowedMethods("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS")
                .allowedHeaders("*")
                .maxAge(3600);
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(jwtInterceptor)
                .addPathPatterns("/api/**")
                .excludePathPatterns(
                        "/api/auth/register",
                        "/api/auth/login"
                );
    }
}

package com.zychen.backend.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.util.StringUtils;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.List;

/**
 * JWT 拦截器保护 {@code /api/**}；放行登录、注册路径。
 * <p>
 * CORS：{@link CorsFilter} 在 Servlet 层处理 {@code OPTIONS} 预检并写入 {@code Access-Control-Allow-Origin} 等头。
 * <p>
 * 常见误区：在 {@code app.cors.allowed-origins} 里只写 {@code http://172.x.x.x:*}（后端 IP），会覆盖默认列表且
 * <strong>不含</strong> {@code http://localhost:*}；而 Flutter Web / 端口转发场景下浏览器 {@code Origin} 仍是
 * {@code http://localhost:端口}，导致预检失败且响应中无 ACAO。默认启用 {@code app.cors.merge-localhost-patterns}
 * 在解析完自定义列表后强制并入 {@code localhost} / {@code 127.0.0.1} 模式（可用配置关闭）。
 * <p>
 * {@code app.cors.allow-all=true} 时允许任意 Origin（仅建议本地调试，生产禁止）。
 */
@Slf4j
@Configuration
@RequiredArgsConstructor
public class WebConfig implements WebMvcConfigurer {

    private static final String CORS_DEFAULT_DEV =
            "http://localhost:*,http://127.0.0.1:*";

    private static final String LOCALHOST_PATTERN = "http://localhost:*";
    private static final String LOOPBACK_PATTERN = "http://127.0.0.1:*";

    private final JwtInterceptor jwtInterceptor;

    /**
     * @param configured 来自 {@code app.cors.allowed-origins}
     * @param mergeLocalhost 为 true 时在非 allow-all 情况下始终并入 localhost / 127 模式（去重）
     */
    private List<String> buildAllowedOriginPatterns(
            boolean allowAllOrigins,
            String configured,
            boolean mergeLocalhost) {
        if (allowAllOrigins) {
            log.warn(
                    "app.cors.allow-all=true：已允许任意 Origin。仅限本地/内网调试，切勿在生产环境开启。");
            return List.of("*");
        }

        LinkedHashSet<String> patterns = new LinkedHashSet<>();
        String raw = configured;
        if (!StringUtils.hasText(raw)) {
            raw = CORS_DEFAULT_DEV;
            log.warn(
                    "app.cors.allowed-origins 未配置，已使用开发默认：{}. 生产请显式配置；"
                            + "若用局域网 IP 打开前端，请再追加 http://该IP:* 等模式。",
                    CORS_DEFAULT_DEV);
        }
        Arrays.stream(raw.split(","))
                .map(String::trim)
                .filter(StringUtils::hasText)
                .forEach(patterns::add);
        if (patterns.isEmpty()) {
            throw new IllegalStateException(
                    "app.cors.allowed-origins 解析后为空，请配置允许的 Origin 模式（逗号分隔），如 http://localhost:*");
        }

        if (mergeLocalhost) {
            patterns.add(LOCALHOST_PATTERN);
            patterns.add(LOOPBACK_PATTERN);
        }

        List<String> list = new ArrayList<>(patterns);
        log.info("CORS allowedOriginPatterns (mergeLocalhost={}): {}", mergeLocalhost, list);
        return list;
    }

    @Bean
    public CorsFilter corsFilter(
            @Value("${app.cors.allowed-origins:}") String corsAllowedOrigins,
            @Value("${app.cors.allow-all:false}") boolean corsAllowAllOrigins,
            @Value("${app.cors.merge-localhost-patterns:true}") boolean mergeLocalhostPatterns) {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOriginPatterns(
                buildAllowedOriginPatterns(corsAllowAllOrigins, corsAllowedOrigins, mergeLocalhostPatterns));
        config.setAllowedMethods(
                Arrays.asList("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", config);
        return new CorsFilter(source);
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // excludePathPatterns 按 URL 路径匹配，与 HTTP 方法无关：OPTIONS /api/auth/login 与 POST 一样被排除
        registry.addInterceptor(jwtInterceptor)
                .addPathPatterns("/api/**")
                .excludePathPatterns(
                        "/api/auth/register",
                        "/api/auth/login"
                );
    }
}

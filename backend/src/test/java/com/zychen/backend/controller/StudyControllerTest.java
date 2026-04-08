package com.zychen.backend.controller;

import com.zychen.backend.config.JwtUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.jdbc.Sql;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 与 docs/api.yaml 中 /study/stats、/study/trend、/study/calendar 及 StudyStats、StudyTrend、StudyCalendar 结构对齐。
 */
@SpringBootTest
@AutoConfigureMockMvc
@Sql(scripts = "/sql/challenge-test-data.sql", executionPhase = Sql.ExecutionPhase.BEFORE_TEST_CLASS)
class StudyControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtUtil jwtUtil;

    private String bearerToken;

    @BeforeEach
    void setUp() {
        bearerToken = "Bearer " + jwtUtil.generateToken(1L, "jwt_challenge_user");
    }

    @Test
    void getStudyStats_success() throws Exception {
        mockMvc.perform(get("/api/study/stats").header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("success"))
                .andExpect(jsonPath("$.data.todayStudy").exists())
                .andExpect(jsonPath("$.data.todayReview").exists())
                .andExpect(jsonPath("$.data.totalWords").exists())
                .andExpect(jsonPath("$.data.masteredWords").exists())
                .andExpect(jsonPath("$.data.wordbookWords").exists())
                .andExpect(jsonPath("$.data.dueReviewCount").exists())
                .andExpect(jsonPath("$.data.totalScore").value(1250))
                .andExpect(jsonPath("$.data.level").value(3));
    }

    @Test
    void getStudyStats_unauthorized() throws Exception {
        mockMvc.perform(get("/api/study/stats"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));
    }

    @Test
    void getStudyTrend_success_withDays() throws Exception {
        mockMvc.perform(get("/api/study/trend")
                        .param("days", "7")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("success"))
                .andExpect(jsonPath("$.data").isArray());
    }

    @Test
    void getStudyTrend_success_defaultDays() throws Exception {
        mockMvc.perform(get("/api/study/trend").header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data").isArray());
    }

    @Test
    void getStudyTrend_unauthorized() throws Exception {
        mockMvc.perform(get("/api/study/trend").param("days", "7"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));
    }

    @Test
    void getStudyCalendar_success() throws Exception {
        mockMvc.perform(get("/api/study/calendar")
                        .param("year", "2026")
                        .param("month", "4")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("success"))
                .andExpect(jsonPath("$.data.year").value(2026))
                .andExpect(jsonPath("$.data.month").value(4))
                .andExpect(jsonPath("$.data.studyDates").isArray());
    }

    @Test
    void getStudyCalendar_unauthorized() throws Exception {
        mockMvc.perform(get("/api/study/calendar")
                        .param("year", "2026")
                        .param("month", "4"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));
    }

    /**
     * 月份非法：业务层 BusinessException(400)，当前全局处理未映射 HTTP 状态，故 HTTP 200 + body.code=400（与 Word 详情 404 行为一致）。
     */
    @Test
    void getStudyCalendar_badMonth() throws Exception {
        mockMvc.perform(get("/api/study/calendar")
                        .param("year", "2026")
                        .param("month", "13")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(400))
                .andExpect(jsonPath("$.message").value("月份无效"));
    }

    @Test
    void getStudyCalendar_badYear() throws Exception {
        mockMvc.perform(get("/api/study/calendar")
                        .param("year", "1969")
                        .param("month", "1")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(400))
                .andExpect(jsonPath("$.message").value("年份无效"));
    }

    @Test
    void getStudyCalendar_missingParams_badRequest() throws Exception {
        mockMvc.perform(get("/api/study/calendar")
                        .param("year", "2026")
                        .header("Authorization", bearerToken))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));
    }
}

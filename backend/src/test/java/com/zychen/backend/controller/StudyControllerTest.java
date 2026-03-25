package com.zychen.backend.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
public class StudyControllerTest {

    @Autowired
    private MockMvc mockMvc;

    /**
     * 测试1：获取学习统计成功
     */
    @Test
    void getStudyStats_success() throws Exception {
        mockMvc.perform(get("/api/study/stats")
                        .header("Authorization", "Bearer mock-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.todayStudy").exists())
                .andExpect(jsonPath("$.data.todayReview").exists())
                .andExpect(jsonPath("$.data.totalWords").exists())
                .andExpect(jsonPath("$.data.masteredWords").exists())
                .andExpect(jsonPath("$.data.wordbookWords").exists())
                .andExpect(jsonPath("$.data.dueReviewCount").exists())
                .andExpect(jsonPath("$.data.totalScore").exists())
                .andExpect(jsonPath("$.data.level").exists());
    }

    /**
     * 测试2：获取学习趋势成功（默认7天）
     */
    @Test
    void getStudyTrend_success_default() throws Exception {
        mockMvc.perform(get("/api/study/trend")
                        .header("Authorization", "Bearer mock-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.length()").value(7));
    }

    /**
     * 测试3：获取学习趋势 - 指定天数
     */
    @Test
    void getStudyTrend_with_days() throws Exception {
        mockMvc.perform(get("/api/study/trend")
                        .param("days", "14")
                        .header("Authorization", "Bearer mock-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.length()").value(14));
    }

    /**
     * 测试4：获取学习趋势 - 验证返回字段
     */
    @Test
    void getStudyTrend_response_fields() throws Exception {
        mockMvc.perform(get("/api/study/trend")
                        .header("Authorization", "Bearer mock-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data[0].date").exists())
                .andExpect(jsonPath("$.data[0].studyCount").exists())
                .andExpect(jsonPath("$.data[0].reviewCount").exists())
                .andExpect(jsonPath("$.data[0].correctRate").exists());
    }

    /**
     * 测试5：获取学习日历成功
     */
    @Test
    void getStudyCalendar_success() throws Exception {
        mockMvc.perform(get("/api/study/calendar")
                        .param("year", "2026")
                        .param("month", "3")
                        .header("Authorization", "Bearer mock-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data").isArray());
    }

    /**
     * 测试6：获取学习日历 - 缺少参数
     */
    @Test
    void getStudyCalendar_failed_missing_params() throws Exception {
        mockMvc.perform(get("/api/study/calendar")
                        .header("Authorization", "Bearer mock-token"))
                .andExpect(status().isBadRequest());
    }

    /**
     * 测试7：获取学习日历 - 验证返回字段
     */
    @Test
    void getStudyCalendar_response_fields() throws Exception {
        mockMvc.perform(get("/api/study/calendar")
                        .param("year", "2026")
                        .param("month", "3")
                        .header("Authorization", "Bearer mock-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data[0].date").exists())
                .andExpect(jsonPath("$.data[0].count").exists())
                .andExpect(jsonPath("$.data[0].level").exists());
    }
}
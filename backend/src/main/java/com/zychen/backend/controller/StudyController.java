package com.zychen.backend.controller;

import com.zychen.backend.dto.response.ApiResponse;
import com.zychen.backend.dto.response.StudyStats;
import com.zychen.backend.dto.response.StudyTrend;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.*;

@Slf4j
@RestController
@RequestMapping("/api/study")
@CrossOrigin(origins = "*")
public class StudyController {

    /**
     * 获取学习统计概览
     * GET /api/study/stats
     */
    @GetMapping("/stats")
    public ApiResponse<StudyStats> getStudyStats(
            @RequestHeader(value = "Authorization", required = false) String auth) {
        log.info("GET /api/study/stats");

        // TODO: 从数据库查询学习统计数据

        StudyStats stats = new StudyStats();
        stats.setTodayStudy(35);
        stats.setTodayReview(80);
        stats.setTotalWords(1245);
        stats.setMasteredWords(876);
        stats.setWordbookWords(128);
        stats.setDueReviewCount(45);
        stats.setTotalScore(1250);
        stats.setLevel(3);

        return ApiResponse.success(stats);
    }

    /**
     * 获取学习趋势（近N天）
     * GET /api/study/trend?days=7
     */
    @GetMapping("/trend")
    public ApiResponse<List<StudyTrend>> getStudyTrend(
            @RequestParam(defaultValue = "7") int days,
            @RequestHeader(value = "Authorization", required = false) String auth) {
        log.info("GET /api/study/trend - days: {}", days);

        // TODO: 从数据库查询学习趋势数据

        List<StudyTrend> trends = new ArrayList<>();
        LocalDate today = LocalDate.now();

        for (int i = days; i > 0; i--) {
            StudyTrend trend = new StudyTrend();
            trend.setDate(today.minusDays(i - 1));
            trend.setStudyCount(25 + (int)(Math.random() * 20));
            trend.setReviewCount(40 + (int)(Math.random() * 50));
            trend.setCorrectRate(0.7 + Math.random() * 0.25);
            trends.add(trend);
        }

        return ApiResponse.success(trends);
    }

    /**
     * 获取学习日历
     * GET /api/study/calendar?year=2026&month=3
     */
    @GetMapping("/calendar")
    public ApiResponse<List<Map<String, Object>>> getStudyCalendar(
            @RequestParam int year,
            @RequestParam int month,
            @RequestHeader(value = "Authorization", required = false) String auth) {
        log.info("GET /api/study/calendar - year: {}, month: {}", year, month);

        // TODO: 从数据库查询指定月份的学习数据

        List<Map<String, Object>> calendarData = new ArrayList<>();

        // Mock 数据
        for (int day = 1; day <= 28; day++) {
            if (Math.random() > 0.6) {
                Map<String, Object> record = new HashMap<>();
                record.put("date", String.format("%d-%02d-%02d", year, month, day));
                record.put("count", 20 + (int)(Math.random() * 80));
                record.put("level", (int)(Math.random() * 4));
                calendarData.add(record);
            }
        }

        return ApiResponse.success(calendarData);
    }
}
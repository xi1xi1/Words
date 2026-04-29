package com.zychen.backend.controller;

import com.zychen.backend.config.JwtUtil;
import com.zychen.backend.dto.response.ApiResponse;
import com.zychen.backend.dto.response.CalendarDTO;
import com.zychen.backend.dto.response.StudyStatsDTO;
import com.zychen.backend.dto.response.StudyTrendDTO;
import com.zychen.backend.service.StudyService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/study")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class StudyController {

    private final StudyService studyService;
    private final JwtUtil jwtUtil;

    @GetMapping("/stats")
    public ApiResponse<StudyStatsDTO> getStudyStats(HttpServletRequest request) {
        Long userId = jwtUtil.getUserIdFromRequest(request);
        log.info("GET /api/study/stats userId={}", userId);
        StudyStatsDTO data = studyService.getStats(userId);
        return ApiResponse.success(data);
    }

    @GetMapping("/trend")
    public ApiResponse<List<StudyTrendDTO>> getStudyTrend(
            HttpServletRequest request,
            @RequestParam(defaultValue = "7") int days) {
        Long userId = jwtUtil.getUserIdFromRequest(request);
        log.info("GET /api/study/trend userId={}, days={}", userId, days);
        List<StudyTrendDTO> data = studyService.getTrend(userId, days);
        return ApiResponse.success(data);
    }

    @GetMapping("/calendar")
    public ApiResponse<CalendarDTO> getStudyCalendar(
            HttpServletRequest request,
            @RequestParam int year,
            @RequestParam int month) {
        Long userId = jwtUtil.getUserIdFromRequest(request);
        log.info("GET /api/study/calendar userId={}, year={}, month={}", userId, year, month);
        CalendarDTO data = studyService.getCalendar(userId, year, month);
        return ApiResponse.success(data);
    }
}

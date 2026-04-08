package com.zychen.backend.service;

import com.zychen.backend.dto.response.CalendarDTO;
import com.zychen.backend.dto.response.StudyStatsDTO;
import com.zychen.backend.dto.response.StudyTrendDTO;

import java.util.List;

public interface StudyService {

    StudyStatsDTO getStats(Long userId);

    List<StudyTrendDTO> getTrend(Long userId, int days);

    CalendarDTO getCalendar(Long userId, int year, int month);
}

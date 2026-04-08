package com.zychen.backend.service.impl;

import com.zychen.backend.common.BusinessException;
import com.zychen.backend.dto.response.CalendarDTO;
import com.zychen.backend.dto.response.StudyStatsDTO;
import com.zychen.backend.dto.response.StudyTrendDTO;
import com.zychen.backend.entity.StudyRecord;
import com.zychen.backend.entity.User;
import com.zychen.backend.mapper.StudyRecordMapper;
import com.zychen.backend.mapper.UserMapper;
import com.zychen.backend.mapper.UserWordMapper;
import com.zychen.backend.service.StudyService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class StudyServiceImpl implements StudyService {

    private static final int MIN_DAYS = 1;
    private static final int MAX_DAYS = 366;

    private final UserMapper userMapper;
    private final UserWordMapper userWordMapper;
    private final StudyRecordMapper studyRecordMapper;

    @Override
    public StudyStatsDTO getStats(Long userId) {
        User user = userMapper.findById(userId);
        if (user == null) {
            throw new BusinessException(404, "用户不存在");
        }
        int todayStudy = userWordMapper.countTodayCompleted(userId);
        int todayReview = userWordMapper.countTodayReviewWords(userId);
        int totalWords = userWordMapper.countLearnedWords(userId);
        int masteredWords = userWordMapper.countMasteredWords(userId);
        int wordbookWords = userWordMapper.countWordbook(userId);
        int dueReviewCount = userWordMapper.countDueReview(userId);

        return StudyStatsDTO.builder()
                .todayStudy(todayStudy)
                .todayReview(todayReview)
                .totalWords(totalWords)
                .masteredWords(masteredWords)
                .wordbookWords(wordbookWords)
                .dueReviewCount(dueReviewCount)
                .totalScore(user.getTotalScore() != null ? user.getTotalScore() : 0)
                .level(user.getLevel() != null ? user.getLevel() : 1)
                .build();
    }

    @Override
    public List<StudyTrendDTO> getTrend(Long userId, int days) {
        int safeDays = Math.min(Math.max(days, MIN_DAYS), MAX_DAYS);
        LocalDate end = LocalDate.now();
        LocalDate start = end.minusDays(safeDays - 1L);
        List<StudyRecord> rows = studyRecordMapper.selectTrendSince(userId, start);
        return rows.stream()
                .map(r -> StudyTrendDTO.builder()
                        .date(r.getStudyDate() != null ? r.getStudyDate().toString() : "")
                        .studyCount(r.getStudyCount() != null ? r.getStudyCount() : 0)
                        .reviewCount(r.getReviewCount() != null ? r.getReviewCount() : 0)
                        .correctRate(r.getCorrectRate() != null ? r.getCorrectRate() : BigDecimal.ZERO)
                        .build())
                .collect(Collectors.toList());
    }

    @Override
    public CalendarDTO getCalendar(Long userId, int year, int month) {
        if (month < 1 || month > 12) {
            throw new BusinessException(400, "月份无效");
        }
        if (year < 1970 || year > 2100) {
            throw new BusinessException(400, "年份无效");
        }
        YearMonth ym = YearMonth.of(year, month);
        LocalDate start = ym.atDay(1);
        LocalDate end = ym.plusMonths(1).atDay(1);
        List<StudyRecord> rows = studyRecordMapper.selectByMonthRange(userId, start, end);
        List<String> dates = rows.stream()
                .map(StudyRecord::getStudyDate)
                .filter(d -> d != null)
                .map(LocalDate::toString)
                .distinct()
                .sorted()
                .collect(Collectors.toList());

        return CalendarDTO.builder()
                .year(year)
                .month(month)
                .studyDates(dates)
                .build();
    }
}

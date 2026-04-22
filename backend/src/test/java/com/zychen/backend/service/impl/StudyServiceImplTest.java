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
import com.zychen.backend.mapper.WordMapper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class StudyServiceImplTest {

    @Mock
    private UserMapper userMapper;

    @Mock
    private UserWordMapper userWordMapper;

    @Mock
    private StudyRecordMapper studyRecordMapper;

    @Mock
    private WordMapper wordMapper;

    @InjectMocks
    private StudyServiceImpl studyService;

    @Test
    void getStats_userNotFound_throws404() {
        when(userMapper.findById(1L)).thenReturn(null);

        BusinessException ex = assertThrows(BusinessException.class, () -> studyService.getStats(1L));
        assertEquals(404, ex.getCode());
        assertEquals("用户不存在", ex.getMessage());
    }

    @Test
    void getStats_nullScoreAndLevel_useDefaults() {
        User u = new User();
        u.setId(1L);
        u.setUsername("u1");
        u.setTotalScore(null);
        u.setLevel(null);
        when(userMapper.findById(1L)).thenReturn(u);

        when(userWordMapper.countTodayCompleted(1L)).thenReturn(3);
        when(userWordMapper.countPendingReviewWords(1L)).thenReturn(2);
        when(userWordMapper.countLearnedWords(1L)).thenReturn(100);
        when(wordMapper.countAllWords()).thenReturn(1800);
        when(userWordMapper.countMasteredWords(1L)).thenReturn(20);
        when(userWordMapper.countWordbook(1L)).thenReturn(5);
        when(userWordMapper.countDueReview(1L)).thenReturn(7);

        StudyStatsDTO dto = studyService.getStats(1L);
        assertEquals(3, dto.getTodayStudy());
        assertEquals(2, dto.getTodayReview());
        assertEquals(100, dto.getTotalWords());
        assertEquals(1800, dto.getTotalVocabulary());
        assertEquals(20, dto.getMasteredWords());
        assertEquals(5, dto.getWordbookWords());
        assertEquals(7, dto.getDueReviewCount());
        assertEquals(0, dto.getTotalScore());
        assertEquals(1, dto.getLevel());
    }

    @Test
    void getTrend_daysLessThanMin_clampedTo1() {
        StudyRecord r = new StudyRecord();
        r.setStudyDate(LocalDate.now());
        r.setStudyCount(1);
        r.setReviewCount(2);
        r.setCorrectRate(new BigDecimal("0.5"));
        when(studyRecordMapper.selectTrendSince(eq(1L), any(LocalDate.class))).thenReturn(List.of(r));

        List<StudyTrendDTO> trend = studyService.getTrend(1L, 0);

        ArgumentCaptor<LocalDate> startCaptor = ArgumentCaptor.forClass(LocalDate.class);
        verify(studyRecordMapper).selectTrendSince(eq(1L), startCaptor.capture());
        assertEquals(LocalDate.now(), startCaptor.getValue());

        assertEquals(1, trend.size());
        assertEquals(LocalDate.now().toString(), trend.get(0).getDate());
        assertEquals(1, trend.get(0).getStudyCount());
        assertEquals(2, trend.get(0).getReviewCount());
        assertEquals(new BigDecimal("0.5"), trend.get(0).getCorrectRate());
    }

    @Test
    void getTrend_daysGreaterThanMax_clampedTo366() {
        when(studyRecordMapper.selectTrendSince(eq(1L), any(LocalDate.class))).thenReturn(List.of());

        studyService.getTrend(1L, 9999);

        ArgumentCaptor<LocalDate> startCaptor = ArgumentCaptor.forClass(LocalDate.class);
        verify(studyRecordMapper).selectTrendSince(eq(1L), startCaptor.capture());
        assertEquals(LocalDate.now().minusDays(365), startCaptor.getValue());
    }

    @Test
    void getTrend_nullFields_mappedToDefaults() {
        StudyRecord r = new StudyRecord();
        r.setStudyDate(null);
        r.setStudyCount(null);
        r.setReviewCount(null);
        r.setCorrectRate(null);
        when(studyRecordMapper.selectTrendSince(eq(1L), any(LocalDate.class))).thenReturn(List.of(r));

        List<StudyTrendDTO> trend = studyService.getTrend(1L, 7);
        assertEquals(1, trend.size());
        assertEquals("", trend.get(0).getDate());
        assertEquals(0, trend.get(0).getStudyCount());
        assertEquals(0, trend.get(0).getReviewCount());
        assertEquals(BigDecimal.ZERO, trend.get(0).getCorrectRate());
    }

    @Test
    void getTrend_daysWithinRange_startDateCalculated() {
        when(studyRecordMapper.selectTrendSince(eq(1L), any(LocalDate.class))).thenReturn(List.of());

        studyService.getTrend(1L, 7);

        ArgumentCaptor<LocalDate> startCaptor = ArgumentCaptor.forClass(LocalDate.class);
        verify(studyRecordMapper).selectTrendSince(eq(1L), startCaptor.capture());
        assertEquals(LocalDate.now().minusDays(6), startCaptor.getValue());
    }

    @Test
    void getCalendar_invalidMonth_throws400() {
        BusinessException ex = assertThrows(BusinessException.class, () -> studyService.getCalendar(1L, 2026, 13));
        assertEquals(400, ex.getCode());
        assertEquals("月份无效", ex.getMessage());
        verifyNoInteractions(studyRecordMapper);
    }

    @Test
    void getCalendar_invalidYear_throws400() {
        BusinessException ex = assertThrows(BusinessException.class, () -> studyService.getCalendar(1L, 1969, 1));
        assertEquals(400, ex.getCode());
        assertEquals("年份无效", ex.getMessage());
        verifyNoInteractions(studyRecordMapper);
    }

    @Test
    void getCalendar_dedupAndSortedDates() {
        StudyRecord a = new StudyRecord();
        a.setStudyDate(LocalDate.of(2026, 4, 2));
        StudyRecord b = new StudyRecord();
        b.setStudyDate(LocalDate.of(2026, 4, 1));
        StudyRecord c = new StudyRecord();
        c.setStudyDate(LocalDate.of(2026, 4, 2));
        StudyRecord d = new StudyRecord();
        d.setStudyDate(null);

        when(studyRecordMapper.selectByMonthRange(eq(1L), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(List.of(a, b, c, d));

        CalendarDTO dto = studyService.getCalendar(1L, 2026, 4);
        assertEquals(2026, dto.getYear());
        assertEquals(4, dto.getMonth());
        assertEquals(List.of("2026-04-01", "2026-04-02"), dto.getStudyDates());
    }

    @Test
    void getCalendar_validMonth_passesCorrectRangeToMapper() {
        when(studyRecordMapper.selectByMonthRange(eq(1L), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(List.of());

        studyService.getCalendar(1L, 2026, 2);

        ArgumentCaptor<LocalDate> startCaptor = ArgumentCaptor.forClass(LocalDate.class);
        ArgumentCaptor<LocalDate> endCaptor = ArgumentCaptor.forClass(LocalDate.class);
        verify(studyRecordMapper).selectByMonthRange(eq(1L), startCaptor.capture(), endCaptor.capture());
        assertEquals(LocalDate.of(2026, 2, 1), startCaptor.getValue());
        assertEquals(LocalDate.of(2026, 3, 1), endCaptor.getValue());
    }
}


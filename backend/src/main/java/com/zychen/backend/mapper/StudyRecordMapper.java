package com.zychen.backend.mapper;

import com.zychen.backend.dto.request.StudyRecordWriteDTO;
import com.zychen.backend.entity.StudyRecord;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDate;
import java.util.List;

@Mapper
public interface StudyRecordMapper {

    /**
     * 按 uk_user_date 查询当日聚合行。
     * SQL 见 StudyRecordMapper.xml — selectByUserIdAndStudyDate
     */
    StudyRecord selectByUserIdAndStudyDate(@Param("userId") Long userId,
                                           @Param("studyDate") LocalDate studyDate);

    /**
     * 插入当日 study_record 行。
     * SQL 见 StudyRecordMapper.xml — insertFromDto
     */
    int insertFromDto(StudyRecordWriteDTO dto);

    /**
     * 按 user_id + study_date 更新计数与正确率。
     * SQL 见 StudyRecordMapper.xml — updateFromDto
     */
    int updateFromDto(StudyRecordWriteDTO dto);

    /**
     * 近 N 天学习趋势（含起止日当天），按日期升序。
     * SQL 见 StudyRecordMapper.xml — selectTrendSince
     */
    List<StudyRecord> selectTrendSince(@Param("userId") Long userId, @Param("startDate") LocalDate startDate);

    /**
     * 指定自然月内有记录的行（用于日历）。
     * SQL 见 StudyRecordMapper.xml — selectByMonthRange
     */
    List<StudyRecord> selectByMonthRange(@Param("userId") Long userId,
                                         @Param("startDate") LocalDate startDate,
                                         @Param("endDate") LocalDate endDate);
}

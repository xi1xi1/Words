package com.zychen.backend.mapper;

import com.zychen.backend.entity.BattleRecord;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface BattleRecordMapper {

    /**
     * 主键查询
     */
    BattleRecord selectById(@Param("id") Long id);

    /**
     * 插入一条闯关记录（回填 id）
     */
    int insert(BattleRecord record);

    /**
     * 按主键更新（全字段）
     */
    int updateById(BattleRecord record);

    /**
     * 按主键删除
     */
    int deleteById(@Param("id") Long id);

    /**
     * 用户闯关历史（按时间倒序），可选按关卡过滤，分页
     */
    List<BattleRecord> listByUserForPage(@Param("userId") Long userId,
                                         @Param("levelType") Integer levelType,
                                         @Param("offset") int offset,
                                         @Param("pageSize") int pageSize);

    /**
     * 与 {@link #listByUserForPage} 配套的总条数
     */
    int countByUser(@Param("userId") Long userId, @Param("levelType") Integer levelType);

    /**
     * 用户在指定关卡的历史最高分；无记录时为 null
     */
    Integer selectBestScore(@Param("userId") Long userId, @Param("levelType") Integer levelType);

    /**
     * 指定关卡下，按每个用户历史最高分排名（MySQL 8 窗口函数）
     */
    List<LevelRankingRow> listLevelRanking(@Param("levelType") Integer levelType,
                                            @Param("limit") int limit);
}

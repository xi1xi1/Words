package com.zychen.backend.mapper;

import lombok.Data;

/**
 * 某关卡下按历史最高分的排行榜行（供 {@link BattleRecordMapper#listLevelRanking} 映射）
 */
@Data
public class LevelRankingRow {
    private Integer rank;
    private Long userId;
    private String username;
    private String avatar;
    private Integer bestScore;
}

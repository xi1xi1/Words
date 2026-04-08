package com.zychen.backend.mapper;

import lombok.Data;

/**
 * 排行榜查询行（含窗口函数排名列 rk），在 Service 中转为 {@link com.zychen.backend.dto.response.RankItem}
 */
@Data
public class LeaderboardRankRow {
    private Long userId;
    private String username;
    private String avatar;
    /** 总榜为 total_score；日/周榜为当日或近7日活跃度得分 */
    private Integer score;
    private Integer rk;
}

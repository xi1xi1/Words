package com.zychen.backend.service;

import com.zychen.backend.dto.response.LeaderboardOverview;
import com.zychen.backend.dto.response.RankItem;

import java.util.List;

public interface LeaderboardService {

    /**
     * 总积分榜前 N 名（按 user.total_score，与 database.md 6.2 一致）
     */
    List<RankItem> getTopUsers(int limit);

    /**
     * 当前用户在总积分榜中的名次（并列同分同名次）；无用户时 null
     */
    Integer getUserRank(Long userId);

    /**
     * 某闯关关卡按历史最高分的排行榜（与 battle_record 聚合一致）
     */
    List<RankItem> getTopUsersByLevel(int levelType, int limit);

    /**
     * HTTP 接口用：type = total | daily | weekly（与 api.yaml 一致）
     */
    LeaderboardOverview getLeaderboard(Long userId, String type, int limit);
}

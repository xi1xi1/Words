package com.zychen.backend.service.impl;

import com.zychen.backend.common.BusinessException;
import com.zychen.backend.dto.response.ChallengeLevelRankItem;
import com.zychen.backend.dto.response.LeaderboardOverview;
import com.zychen.backend.dto.response.RankItem;
import com.zychen.backend.mapper.LeaderboardMapper;
import com.zychen.backend.mapper.LeaderboardRankRow;
import com.zychen.backend.service.ChallengeService;
import com.zychen.backend.service.LeaderboardService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class LeaderboardServiceImpl implements LeaderboardService {

    private static final int MIN_LIMIT = 1;
    private static final int MAX_LIMIT = 100;

    private final LeaderboardMapper leaderboardMapper;
    private final ChallengeService challengeService;

    @Override
    public List<RankItem> getTopUsers(int limit) {
        int safe = clampLimit(limit);
        return leaderboardMapper.selectTopByTotalScore(safe).stream()
                .map(this::toRankItem)
                .collect(Collectors.toList());
    }

    @Override
    public Integer getUserRank(Long userId) {
        if (userId == null) {
            return null;
        }
        return leaderboardMapper.selectUserRankByTotalScore(userId);
    }

    @Override
    public List<RankItem> getTopUsersByLevel(int levelType, int limit) {
        int safe = clampLimit(limit);
        List<ChallengeLevelRankItem> rows = challengeService.getLevelRanking(levelType, safe);
        return rows.stream().map(this::levelToRankItem).collect(Collectors.toList());
    }

    @Override
    public LeaderboardOverview getLeaderboard(Long userId, String type, int limit) {
        int safe = clampLimit(limit);
        String t = type == null || type.isBlank() ? "total" : type.trim().toLowerCase();

        return switch (t) {
            case "daily" -> LeaderboardOverview.builder()
                    .list(leaderboardMapper.selectTopByDailyActivity(safe).stream().map(this::toRankItem).collect(Collectors.toList()))
                    .myRank(leaderboardMapper.selectUserRankByDailyActivity(userId))
                    .build();
            case "weekly" -> LeaderboardOverview.builder()
                    .list(leaderboardMapper.selectTopByWeeklyActivity(safe).stream().map(this::toRankItem).collect(Collectors.toList()))
                    .myRank(leaderboardMapper.selectUserRankByWeeklyActivity(userId))
                    .build();
            case "total" -> LeaderboardOverview.builder()
                    .list(getTopUsers(safe))
                    .myRank(getUserRank(userId))
                    .build();
            default -> throw new BusinessException(400, "不支持的排行榜类型，可选：total、daily、weekly");
        };
    }

    private static int clampLimit(int limit) {
        return Math.min(Math.max(limit, MIN_LIMIT), MAX_LIMIT);
    }

    private RankItem toRankItem(LeaderboardRankRow row) {
        RankItem item = new RankItem();
        item.setRank(row.getRk());
        item.setUserId(row.getUserId());
        item.setUsername(row.getUsername());
        item.setAvatar(row.getAvatar());
        item.setTotalScore(row.getScore());
        return item;
    }

    private RankItem levelToRankItem(ChallengeLevelRankItem c) {
        RankItem item = new RankItem();
        item.setRank(c.getRank());
        item.setUserId(c.getUserId());
        item.setUsername(c.getUsername());
        item.setAvatar(c.getAvatar());
        item.setTotalScore(c.getBestScore());
        return item;
    }
}

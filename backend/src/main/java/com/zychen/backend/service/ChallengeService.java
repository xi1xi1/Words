package com.zychen.backend.service;

import com.zychen.backend.dto.request.ChallengeSubmitRequest;
import com.zychen.backend.dto.response.ChallengeLevelRankItem;
import com.zychen.backend.dto.response.ChallengeRecordsPage;
import com.zychen.backend.dto.response.ChallengeStartResponse;
import com.zychen.backend.dto.response.ChallengeSubmitResponse;

import java.util.List;

public interface ChallengeService {

    /**
     * 开始闯关：从词库随机抽题（每题 4 个选项，正确答案在索引 0，与客户端约定一致）
     */
    ChallengeStartResponse startChallenge(Long userId, Integer levelType);

    /**
     * 提交闯关：计分、加总积分、写入 battle_record
     */
    ChallengeSubmitResponse submitChallenge(Long userId, ChallengeSubmitRequest request);

    /**
     * 写入一条闯关记录，返回主键 id
     */
    Long saveRecord(Long userId, Integer levelType, Integer score, Integer correctCount,
                    Integer totalCount, Integer duration, String detailsJson);

    /**
     * 当前用户闯关历史（按时间倒序分页）
     *
     * @param levelType 为 null 时不按关卡过滤
     */
    ChallengeRecordsPage getUserHistory(Long userId, Integer levelType, int page, int size);

    /**
     * 指定关卡下按历史最高分的排行榜
     */
    List<ChallengeLevelRankItem> getLevelRanking(Integer levelType, int limit);

    /**
     * 用户在指定关卡的历史最高分；无记录时为 null
     */
    Integer getBestScore(Long userId, Integer levelType);
}

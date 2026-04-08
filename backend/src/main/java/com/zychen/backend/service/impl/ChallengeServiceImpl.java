package com.zychen.backend.service.impl;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zychen.backend.common.BusinessException;
import com.zychen.backend.dto.request.ChallengeSubmitRequest;
import com.zychen.backend.dto.response.ChallengeLevelRankItem;
import com.zychen.backend.dto.response.ChallengeQuestion;
import com.zychen.backend.dto.response.ChallengeRecordItem;
import com.zychen.backend.dto.response.ChallengeRecordsPage;
import com.zychen.backend.dto.response.ChallengeStartResponse;
import com.zychen.backend.dto.response.ChallengeSubmitResponse;
import com.zychen.backend.entity.BattleRecord;
import com.zychen.backend.entity.User;
import com.zychen.backend.entity.Word;
import com.zychen.backend.mapper.BattleRecordMapper;
import com.zychen.backend.mapper.LevelRankingRow;
import com.zychen.backend.mapper.UserMapper;
import com.zychen.backend.mapper.WordMapper;
import com.zychen.backend.service.ChallengeService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ChallengeServiceImpl implements ChallengeService {

    private static final int MIN_LEVEL = 1;
    private static final int MAX_LEVEL = 3;
    private static final int DEFAULT_RANK_LIMIT = 50;
    private static final int MAX_PAGE_SIZE = 100;

    private final BattleRecordMapper battleRecordMapper;
    private final WordMapper wordMapper;
    private final UserMapper userMapper;
    private final ObjectMapper objectMapper;

    @Override
    public ChallengeStartResponse startChallenge(Long userId, Integer levelType) {
        validateUserId(userId);
        validateLevelType(levelType);

        int questionCount = questionCountForLevel(levelType);
        int poolSize = Math.max(questionCount + 15, 20);
        List<Word> poolWords = wordMapper.getRandomWords(poolSize);
        if (poolWords.size() < questionCount) {
            throw new BusinessException(400, "词库单词数量不足，无法开始闯关");
        }

        List<ChallengeQuestion> questions = new ArrayList<>(questionCount);
        for (int i = 0; i < questionCount; i++) {
            questions.add(buildQuestion(poolWords.get(i), poolWords));
        }

        ChallengeStartResponse response = new ChallengeStartResponse();
        response.setChallengeId("ch_" + levelType + "_" + System.currentTimeMillis());
        response.setQuestions(questions);
        response.setTimeLimit(timeLimitForLevel(levelType));
        return response;
    }

    @Override
    @Transactional
    public ChallengeSubmitResponse submitChallenge(Long userId, ChallengeSubmitRequest request) {
        validateUserId(userId);
        validateLevelType(request.getLevelType());

        List<ChallengeSubmitRequest.AnswerItem> answers = request.getAnswers();
        if (answers == null || answers.isEmpty()) {
            throw new BusinessException(400, "答案列表不能为空");
        }

        int totalCount = answers.size();
        int correctCount = (int) answers.stream()
                .filter(a -> a.getSelectedIndex() != null && a.getSelectedIndex() == 0)
                .count();
        double accuracy = (double) correctCount / totalCount;
        int score = (int) (accuracy * 1000);
        int addedScore = (int) (score * 0.1);

        boolean anyTime = answers.stream().anyMatch(a -> a.getTimeSpent() != null);
        Integer duration = anyTime
                ? answers.stream()
                .map(ChallengeSubmitRequest.AnswerItem::getTimeSpent)
                .filter(Objects::nonNull)
                .mapToInt(Integer::intValue)
                .sum()
                : null;

        String detailsJson;
        try {
            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("challengeId", request.getChallengeId());
            payload.put("levelType", request.getLevelType());
            payload.put("answers", answers);
            detailsJson = objectMapper.writeValueAsString(payload);
        } catch (JsonProcessingException e) {
            log.error("闯关详情序列化失败", e);
            throw new BusinessException(500, "结果序列化失败");
        }

        saveRecord(userId, request.getLevelType(), score, correctCount, totalCount, duration, detailsJson);

        int updated = userMapper.addScore(userId, addedScore);
        if (updated == 0) {
            throw new BusinessException(404, "用户不存在");
        }
        User user = userMapper.findById(userId);
        if (user == null) {
            throw new BusinessException(404, "用户不存在");
        }

        ChallengeSubmitResponse response = new ChallengeSubmitResponse();
        response.setScore(score);
        response.setCorrectCount(correctCount);
        response.setTotalCount(totalCount);
        response.setAccuracy(accuracy);
        response.setAddedScore(addedScore);
        response.setTotalScore(user.getTotalScore());
        return response;
    }

    @Override
    @Transactional
    public Long saveRecord(Long userId, Integer levelType, Integer score, Integer correctCount,
                           Integer totalCount, Integer duration, String detailsJson) {
        validateUserId(userId);
        validateLevelType(levelType);
        if (score == null || correctCount == null || totalCount == null) {
            throw new BusinessException(400, "得分与答题数量不能为空");
        }
        if (totalCount < 0 || correctCount < 0 || correctCount > totalCount) {
            throw new BusinessException(400, "答题数量不合法");
        }

        BattleRecord record = new BattleRecord();
        record.setUserId(userId);
        record.setLevelType(levelType);
        record.setScore(score);
        record.setCorrectCount(correctCount);
        record.setTotalCount(totalCount);
        record.setDuration(duration);
        record.setDetails(detailsJson);

        battleRecordMapper.insert(record);
        log.info("保存闯关记录: id={}, userId={}, levelType={}, score={}",
                record.getId(), userId, levelType, score);
        return record.getId();
    }

    @Override
    public ChallengeRecordsPage getUserHistory(Long userId, Integer levelType, int page, int size) {
        validateUserId(userId);
        if (levelType != null) {
            validateLevelType(levelType);
        }

        int safePage = Math.max(page, 1);
        int safeSize = Math.min(Math.max(size, 1), MAX_PAGE_SIZE);
        int offset = (safePage - 1) * safeSize;

        int total = battleRecordMapper.countByUser(userId, levelType);
        List<BattleRecord> rows = battleRecordMapper.listByUserForPage(userId, levelType, offset, safeSize);

        List<ChallengeRecordItem> content = rows.stream()
                .map(this::toRecordItem)
                .collect(Collectors.toList());

        return ChallengeRecordsPage.builder()
                .content(content)
                .total(total)
                .page(safePage)
                .size(safeSize)
                .build();
    }

    @Override
    public List<ChallengeLevelRankItem> getLevelRanking(Integer levelType, int limit) {
        validateLevelType(levelType);
        int safeLimit = limit <= 0 ? DEFAULT_RANK_LIMIT : Math.min(limit, MAX_PAGE_SIZE);

        List<LevelRankingRow> rows = battleRecordMapper.listLevelRanking(levelType, safeLimit);
        return rows.stream()
                .map(r -> ChallengeLevelRankItem.builder()
                        .rank(r.getRank())
                        .userId(r.getUserId())
                        .username(r.getUsername())
                        .avatar(r.getAvatar())
                        .bestScore(r.getBestScore())
                        .build())
                .collect(Collectors.toList());
    }

    @Override
    public Integer getBestScore(Long userId, Integer levelType) {
        validateUserId(userId);
        validateLevelType(levelType);
        return battleRecordMapper.selectBestScore(userId, levelType);
    }

    private static int questionCountForLevel(int levelType) {
        return switch (levelType) {
            case 1 -> 5;
            case 2 -> 10;
            case 3 -> 15;
            default -> 5;
        };
    }

    private static int timeLimitForLevel(int levelType) {
        return switch (levelType) {
            case 1 -> 60;
            case 2 -> 90;
            case 3 -> 120;
            default -> 60;
        };
    }

    private ChallengeQuestion buildQuestion(Word target, List<Word> pool) {
        String correct = firstMeaning(target);
        List<String> wrongs = new ArrayList<>();
        for (Word w : pool) {
            if (Objects.equals(w.getId(), target.getId())) {
                continue;
            }
            String m = firstMeaning(w);
            if (!m.equals(correct) && !wrongs.contains(m)) {
                wrongs.add(m);
            }
            if (wrongs.size() >= 3) {
                break;
            }
        }
        int pad = 1;
        while (wrongs.size() < 3) {
            wrongs.add("备选项" + pad++);
        }

        List<String> options = new ArrayList<>(4);
        options.add(correct);
        options.addAll(wrongs.subList(0, 3));

        ChallengeQuestion q = new ChallengeQuestion();
        q.setId(target.getId());
        q.setWord(target.getWord());
        q.setOptions(options);
        q.setCorrectIndex(0);
        return q;
    }

    private String firstMeaning(Word w) {
        try {
            List<String> list = objectMapper.readValue(w.getMeaning(), new TypeReference<List<String>>() {});
            if (list == null || list.isEmpty()) {
                return w.getWord();
            }
            return list.get(0);
        } catch (Exception e) {
            log.warn("解析释义失败 wordId={}", w.getId());
            return w.getWord();
        }
    }

    private void validateUserId(Long userId) {
        if (userId == null) {
            throw new BusinessException(401, "未登录");
        }
    }

    private void validateLevelType(Integer levelType) {
        if (levelType == null || levelType < MIN_LEVEL || levelType > MAX_LEVEL) {
            throw new BusinessException(400, "关卡等级必须为 1~3");
        }
    }

    private ChallengeRecordItem toRecordItem(BattleRecord br) {
        double rate = br.getTotalCount() != null && br.getTotalCount() > 0
                ? (double) br.getCorrectCount() / br.getTotalCount()
                : 0.0;
        return ChallengeRecordItem.builder()
                .id(br.getId())
                .levelType(br.getLevelType())
                .levelName(levelName(br.getLevelType()))
                .score(br.getScore())
                .correctCount(br.getCorrectCount())
                .totalCount(br.getTotalCount())
                .correctRate(rate)
                .createTime(br.getCreateTime())
                .duration(br.getDuration())
                .build();
    }

    private static String levelName(Integer levelType) {
        if (levelType == null) {
            return "未知";
        }
        return switch (levelType) {
            case 1 -> "初级场";
            case 2 -> "中级场";
            case 3 -> "高级场";
            default -> "未知";
        };
    }
}

package com.zychen.backend.service.impl;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zychen.backend.common.BusinessException;
import com.zychen.backend.dto.request.LearnRequest;
import com.zychen.backend.dto.request.StudyRecordWriteDTO;
import com.zychen.backend.dto.response.DailyWordsResponse;
import com.zychen.backend.dto.response.LearnResponse;
import com.zychen.backend.dto.response.NextWordInfo;
import com.zychen.backend.dto.response.Word;
import com.zychen.backend.entity.StudyRecord;
import com.zychen.backend.entity.UserWord;
import com.zychen.backend.mapper.StudyRecordMapper;
import com.zychen.backend.mapper.UserWordMapper;
import com.zychen.backend.mapper.WordMapper;
import com.zychen.backend.service.WordService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class WordServiceImpl implements WordService {

    private final WordMapper wordMapper;
    private final UserWordMapper userWordMapper;
    private final StudyRecordMapper studyRecordMapper;

    private static final int NEW_WORDS_PER_DAY = 10;
    private static final int REVIEW_WORDS_PER_DAY = 20;
    private static final int DAILY_TOTAL_LIMIT = 30;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public DailyWordsResponse getDailyWords(Long userId) {
        log.info("获取用户今日单词: userId={}", userId);

        // 1. 获取需要复习的单词（学习中、今日未掌握、到复习时间）
        List<UserWord> reviewUserWords = userWordMapper.getReviewWords(userId, REVIEW_WORDS_PER_DAY);
        List<Word> reviewWords = reviewUserWords.stream()
                .map(uw -> convertToWord(uw.getWordId()))
                .collect(Collectors.toList());

        // 2. 获取已学过的单词ID列表
        List<Long> learnedWordIds = userWordMapper.getLearnedWordIds(userId);

        // 3. 获取新词（排除已学过的）
        List<com.zychen.backend.entity.Word> newWordsEntities;
        if (learnedWordIds.isEmpty()) {
            newWordsEntities = wordMapper.getLatestWords(NEW_WORDS_PER_DAY);
        } else {
            newWordsEntities = wordMapper.getLatestWordsExclude(learnedWordIds, NEW_WORDS_PER_DAY);
        }

        List<Word> newWords = newWordsEntities.stream()
                .map(this::convertToWordDto)
                .collect(Collectors.toList());

        DailyWordsResponse response = new DailyWordsResponse();
        response.setNewWords(newWords);
        response.setReviewWords(reviewWords);

        log.info("获取今日单词成功: userId={}, 新词数={}, 复习词数={}",
                userId, newWords.size(), reviewWords.size());
        return response;
    }

    @Override
    @Transactional
    public LearnResponse submitLearnResult(Long userId, LearnRequest request) {
        log.info("提交学习结果: userId={}, wordId={}, stage={}, isCorrect={}",
                userId, request.getWordId(), request.getStage(), request.getIsCorrect());

        // 1. 获取或创建用户单词记录（需在 processLearnResult 前判定新学/复习，因会改写 next_review 等）
        UserWord userWord = userWordMapper.findByUserIdAndWordId(userId, request.getWordId());
        final boolean isReviewWord;
        if (userWord == null) {
            isReviewWord = false;
            userWord = createNewUserWord(userId, request.getWordId());
        } else {
            isReviewWord = isReviewQueueUserWord(userWord);
        }

        // 2. 验证阶段匹配
        if (userWord.getStudyStage() != request.getStage()) {
            log.warn("阶段不匹配: 期望 stage={}, 实际 stage={}",
                    userWord.getStudyStage(), request.getStage());
            throw new BusinessException(400, "学习阶段不匹配，请刷新页面重试");
        }

        // 3. 处理学习结果
        processLearnResult(userWord, request);

        // 3.1 聚合写入当日 study_record（uk_user_date）
        upsertDailyStudyRecord(userId, isReviewWord, Boolean.TRUE.equals(request.getIsCorrect()));

        // 3.2 若刚刚“掌握完成”且今日待学队列已耗尽，则自动补充下一批新词
        // 今日待学队列耗尽条件：user_word 中 status=0、today_mastered=0、next_review <= NOW() 的记录为空
        if (Integer.valueOf(1).equals(userWord.getTodayMastered())) {
            List<UserWord> remainingTodayLearningWords = userWordMapper.getTodayLearningWords(userId);
            if (remainingTodayLearningWords == null || remainingTodayLearningWords.isEmpty()) {
                replenishDailyNewWords(userId);
            }
        }

        // 4. 获取今日学习统计
        int completedCount = getTodayCompletedCount(userId);
        int totalCount = getTodayTotalCount(userId);

        // 5. 获取下一个单词（从今日学习列表中选取）
        NextWordInfo nextWord = getNextWordFromTodayList(userId);

        log.info("学习结果处理完成: userId={}, wordId={}, 新阶段={}, 今日掌握={}, 今日进度={}/{}",
                userId, request.getWordId(), userWord.getStudyStage(),
                userWord.getTodayMastered(), completedCount, totalCount);

        return new LearnResponse(nextWord, completedCount, totalCount);
    }

    @Override
    @Transactional
    public void replenishDailyNewWords(Long userId) {
        // 保护：如果队列并未耗尽，不重复补充
        List<UserWord> todayLearningWords = userWordMapper.getTodayLearningWords(userId);
        if (todayLearningWords != null && !todayLearningWords.isEmpty()) {
            return;
        }

        // 获取已学过/已被分配过的单词（user_word 中出现过的都算已分配）
        List<Long> learnedWordIds = userWordMapper.getLearnedWordIds(userId);

        // 从词库中选取未出现于 user_word 的新词，组成下一批
        List<com.zychen.backend.entity.Word> candidates;
        if (learnedWordIds == null || learnedWordIds.isEmpty()) {
            candidates = wordMapper.getLatestWords(NEW_WORDS_PER_DAY);
        } else {
            candidates = wordMapper.getLatestWordsExclude(learnedWordIds, NEW_WORDS_PER_DAY);
        }

        if (candidates == null || candidates.isEmpty()) {
            log.info("今日待学队列耗尽但词库已无新词可补充: userId={}", userId);
            return;
        }

        LocalDateTime now = LocalDateTime.now();
        int inserted = 0;
        for (com.zychen.backend.entity.Word w : candidates) {
            if (w == null) {
                continue;
            }
            UserWord row = new UserWord();
            row.setUserId(userId);
            row.setWordId(w.getId());
            row.setStatus(0);             // 学习中
            row.setStudyStage(1);        // 从阶段1开始
            row.setTodayMastered(0);     // 今日未掌握
            row.setReviewCount(0);       // 新词：复习次数从0开始
            row.setNextReview(now);      // 立刻进入今日待学队列
            row.setMemoryScore(BigDecimal.ZERO);
            row.setLastStudyTime(null);

            int rows = userWordMapper.insert(row);
            if (rows > 0) {
                inserted++;
            }
        }

        log.info("补充今日新词队列成功: userId={}, 本批请求={}, 实际插入={}",
                userId, NEW_WORDS_PER_DAY, inserted);
    }

    @Override
    public List<Word> searchWords(String keyword, Integer page, Integer size) {
        log.info("搜索单词: keyword={}, page={}, size={}", keyword, page, size);

        int offset = (page - 1) * size;
        List<com.zychen.backend.entity.Word> words = wordMapper.search(keyword, offset, size);

        return words.stream()
                .map(this::convertToWordDto)
                .collect(Collectors.toList());
    }

    @Override
    public Word getWordDetail(Long wordId) {
        log.info("获取单词详情: wordId={}", wordId);

        com.zychen.backend.entity.Word word = wordMapper.findById(wordId);
        if (word == null) {
            throw new BusinessException(404, "单词不存在");
        }

        return convertToWordDto(word);
    }

    // ==================== 私有方法 ====================

    /**
     * 与 getReviewWords 一致：学习中、今日未掌握、且已到复习时间 → 视为「复习词」提交；否则为「新学词」路径。
     */
    private boolean isReviewQueueUserWord(UserWord uw) {
        if (uw == null) {
            return false;
        }
        if (!Integer.valueOf(0).equals(uw.getStatus())) {
            return false;
        }
        if (!Integer.valueOf(0).equals(uw.getTodayMastered())) {
            return false;
        }
        if (uw.getNextReview() == null) {
            return false;
        }
        return !uw.getNextReview().isAfter(LocalDateTime.now());
    }

    /**
     * 按 user_id + study_date 插入或更新 study_record，并刷新 correct_rate（今日正确数 / 今日学习总次数）。
     */
    private void upsertDailyStudyRecord(Long userId, boolean isReviewWord, boolean isCorrect) {
        LocalDate today = LocalDate.now();
        StudyRecord existing = studyRecordMapper.selectByUserIdAndStudyDate(userId, today);

        int oldStudy = existing != null && existing.getStudyCount() != null ? existing.getStudyCount() : 0;
        int oldReview = existing != null && existing.getReviewCount() != null ? existing.getReviewCount() : 0;
        BigDecimal oldRate = existing != null && existing.getCorrectRate() != null
                ? existing.getCorrectRate()
                : BigDecimal.ZERO;

        int newStudy = oldStudy + (isReviewWord ? 0 : 1);
        int newReview = oldReview + (isReviewWord ? 1 : 0);
        int oldTotal = oldStudy + oldReview;
        BigDecimal oldCorrectApprox = oldTotal == 0
                ? BigDecimal.ZERO
                : oldRate.multiply(BigDecimal.valueOf(oldTotal)).setScale(0, RoundingMode.HALF_UP);
        int newTotal = oldTotal + 1;
        BigDecimal newCorrectApprox = oldCorrectApprox.add(isCorrect ? BigDecimal.ONE : BigDecimal.ZERO);
        BigDecimal newRate = newTotal <= 0
                ? BigDecimal.ZERO.setScale(3, RoundingMode.HALF_UP)
                : newCorrectApprox.divide(BigDecimal.valueOf(newTotal), 3, RoundingMode.HALF_UP);
        if (newRate.compareTo(BigDecimal.ONE) > 0) {
            newRate = BigDecimal.ONE.setScale(3, RoundingMode.HALF_UP);
        }

        StudyRecordWriteDTO dto = new StudyRecordWriteDTO(userId, today, newStudy, newReview, newRate);
        if (existing == null) {
            studyRecordMapper.insertFromDto(dto);
            log.info("study_record 插入: userId={}, studyDate={}, studyCount={}, reviewCount={}, correctRate={}, isReviewWord={}, isCorrect={}",
                    userId, today, newStudy, newReview, newRate, isReviewWord, isCorrect);
        } else {
            int rows = studyRecordMapper.updateFromDto(dto);
            log.info("study_record 更新: userId={}, studyDate={}, studyCount={}, reviewCount={}, correctRate={}, rows={}, isReviewWord={}, isCorrect={}",
                    userId, today, newStudy, newReview, newRate, rows, isReviewWord, isCorrect);
        }
    }

    /**
     * 创建新的用户单词记录
     */
    private UserWord createNewUserWord(Long userId, Long wordId) {
        UserWord userWord = new UserWord();
        userWord.setUserId(userId);
        userWord.setWordId(wordId);
        userWord.setStatus(0);           // 学习中
        userWord.setStudyStage(1);       // 从阶段1开始
        userWord.setTodayMastered(0);    // 今日未掌握
        userWord.setReviewCount(0);
        userWord.setMemoryScore(BigDecimal.ZERO);
        userWord.setLastStudyTime(LocalDateTime.now());
        userWord.setNextReview(LocalDateTime.now().plusDays(1));

        userWordMapper.insert(userWord);
        log.info("创建新词记录: userId={}, wordId={}", userId, wordId);
        return userWord;
    }

    /**
     * 处理学习结果（渐进式学习核心逻辑）
     */
    private void processLearnResult(UserWord userWord, LearnRequest request) {
        int currentStage = userWord.getStudyStage();
        boolean isCorrect = request.getIsCorrect();

        if (isCorrect) {
            // 答对：进入下一阶段
            if (currentStage < 3) {
                // 未到最终阶段，进入下一阶段
                userWord.setStudyStage(currentStage + 1);
                userWord.setLastStudyTime(LocalDateTime.now());
                userWord.setMemoryScore(
                        calculateMemoryScore(userWord.getMemoryScore(), true, currentStage)
                );
                log.debug("答对，进入下一阶段: stage {} -> {}", currentStage, currentStage + 1);
            } else {
                // 阶段3答对：今日掌握该单词
                userWord.setTodayMastered(1);
                userWord.setStatus(1);  // 标记为已掌握
                userWord.setLastStudyTime(LocalDateTime.now());
                userWord.setMemoryScore(
                        calculateMemoryScore(userWord.getMemoryScore(), true, 3)
                );
                userWord.setNextReview(
                        calculateNextReview(userWord.getReviewCount() + 1, true)
                );
                userWord.setReviewCount(userWord.getReviewCount() + 1);
                log.debug("阶段3答对，今日掌握该单词");
            }
        } else {
            // 答错：重置到阶段1
            userWord.setStudyStage(1);
            userWord.setTodayMastered(0);
            userWord.setLastStudyTime(LocalDateTime.now());
            userWord.setMemoryScore(
                    calculateMemoryScore(userWord.getMemoryScore(), false, currentStage)
            );
            userWord.setNextReview(LocalDateTime.now().plusDays(1));

            // 如果之前是已掌握状态，降级回学习中
            if (userWord.getStatus() == 1) {
                userWord.setStatus(0);
            }
            log.debug("答错，重置到阶段1");
        }

        // 更新数据库
        userWordMapper.updateAfterLearn(
                userWord.getUserId(),
                userWord.getWordId(),
                userWord.getStatus(),
                userWord.getStudyStage(),
                userWord.getTodayMastered(),
                userWord.getNextReview(),
                userWord.getMemoryScore(),
                userWord.getLastStudyTime()
        );
    }

    /**
     * 从今日学习列表中获取下一个单词
     * 今日学习列表 = 所有需要学习的单词（未掌握且到复习时间）
     */
    private NextWordInfo getNextWordFromTodayList(Long userId) {
        // 获取今日所有需要学习的单词（学习中、今日未掌握、到复习时间）
        List<UserWord> todayLearningWords = userWordMapper.getTodayLearningWords(userId);

        log.debug("今日学习列表大小: {}", todayLearningWords.size());

        if (todayLearningWords.isEmpty()) {
            log.info("今日学习完成，无下一个单词");
            return null;
        }

        // 随机选择一个单词（让学习更有趣，避免单调）
        // 也可以按记忆强度排序，优先学习记忆强度低的
        UserWord selected = todayLearningWords.get(new Random().nextInt(todayLearningWords.size()));

        log.debug("选中下一个单词: wordId={}, stage={}", selected.getWordId(), selected.getStudyStage());

        // 获取单词详情
        com.zychen.backend.entity.Word word = wordMapper.findById(selected.getWordId());
        if (word == null) {
            log.error("单词不存在: wordId={}", selected.getWordId());
            return null;
        }

        // 构建返回对象
        NextWordInfo nextWord = new NextWordInfo();
        nextWord.setWordId(word.getId());
        nextWord.setWord(word.getWord());
        nextWord.setMeaning(parseJsonToList(word.getMeaning()));
        nextWord.setPhonetic(word.getPhonetic());
        nextWord.setStage(selected.getStudyStage());

        // 根据阶段添加额外信息
        if (selected.getStudyStage() == 1) {
            // 阶段1：需要4个选项（正确释义 + 3个干扰项）
            List<String> options = getInterferenceOptions(word.getId(), word.getMeaning());
            nextWord.setOptions(options);
            log.debug("阶段1，生成选项: {}", options);
        } else if (selected.getStudyStage() == 2) {
            // 阶段2：需要例句
            List<String> examples = parseJsonToList(word.getExample());
            if (!examples.isEmpty()) {
                nextWord.setExample(examples.get(0));
                log.debug("阶段2，例句: {}", examples.get(0));
            }
        }
        // 阶段3：不需要额外信息

        return nextWord;
    }

    /**
     * 获取今日已完成单词数（today_mastered = 1）
     */
    private int getTodayCompletedCount(Long userId) {
        return userWordMapper.countTodayCompleted(userId);
    }

    /**
     * 获取今日需要学习的单词总数
     * = min(复习词数 + 新词数, 每日上限)
     */
    private int getTodayTotalCount(Long userId) {
        int reviewCount = userWordMapper.countTodayReviewWords(userId);
        int newCount = wordMapper.countNewWords(userId);
        int total = Math.min(reviewCount + newCount, DAILY_TOTAL_LIMIT);
        log.debug("今日统计: 复习词={}, 新词={}, 总计={}", reviewCount, newCount, total);
        return total;
    }

    /**
     * 生成干扰项（从其他单词中随机取3个释义）
     */
    private List<String> getInterferenceOptions(Long currentWordId, String currentMeaningJson) {
        List<String> correctMeanings = parseJsonToList(currentMeaningJson);
        String correct = correctMeanings.isEmpty() ? "" : correctMeanings.get(0);

        // 随机获取3个其他单词的释义
        List<com.zychen.backend.entity.Word> otherWords = wordMapper.getRandomWordsExclude(currentWordId, 3);

        List<String> options = new ArrayList<>();
        options.add(correct);

        for (com.zychen.backend.entity.Word w : otherWords) {
            List<String> meanings = parseJsonToList(w.getMeaning());
            if (!meanings.isEmpty()) {
                options.add(meanings.get(0));
            }
        }

        // 打乱顺序
        Collections.shuffle(options);
        return options;
    }

    /**
     * 根据 wordId 获取 Word DTO
     */
    private Word convertToWord(Long wordId) {
        com.zychen.backend.entity.Word word = wordMapper.findById(wordId);
        return convertToWordDto(word);
    }

    /**
     * 实体转 DTO
     */
    private Word convertToWordDto(com.zychen.backend.entity.Word entity) {
        Word dto = new Word();
        dto.setId(entity.getId());
        dto.setWord(entity.getWord());
        dto.setMeaning(parseJsonToList(entity.getMeaning()));
        dto.setPhonetic(entity.getPhonetic());
        dto.setExample(parseJsonToList(entity.getExample()));
        return dto;
    }

    /**
     * 解析 JSON 字符串为 List<String>
     */
    private List<String> parseJsonToList(String json) {
        if (json == null || json.isEmpty()) {
            return new ArrayList<>();
        }
        try {
            List<String> parsed = objectMapper.readValue(json, new TypeReference<List<String>>() {});
            return parsed.stream()
                    .map(this::fixCommonMojibake)
                    .collect(Collectors.toList());
        } catch (Exception ex) {
            // 兼容历史非标准 JSON 文本
            String trimmed = json.trim();
            if (trimmed.startsWith("[") && trimmed.endsWith("]")) {
                String content = trimmed.substring(1, trimmed.length() - 1);
                if (content.isEmpty()) {
                    return new ArrayList<>();
                }
                String[] items = content.split(",");
                List<String> result = new ArrayList<>();
                for (String item : items) {
                    String cleaned = item.trim().replaceAll("^\"|\"$", "");
                    result.add(fixCommonMojibake(cleaned));
                }
                return result;
            }
        }
        return new ArrayList<>();
    }

    /**
     * 修正常见 UTF-8/Latin-1 错位（例如：æœºä¼š -> 机会）。
     * 仅在原文本不含中文、且重解码后出现中文时才替换，避免误伤。
     */
    private String fixCommonMojibake(String text) {
        if (text == null || text.isEmpty() || containsCjk(text)) {
            return text;
        }
        String recovered = new String(text.getBytes(StandardCharsets.ISO_8859_1), StandardCharsets.UTF_8);
        if (containsCjk(recovered)) {
            log.warn("检测到疑似乱码并已修正: {} -> {}", text, recovered);
            return recovered;
        }
        return text;
    }

    private boolean containsCjk(String text) {
        for (int i = 0; i < text.length(); i++) {
            char ch = text.charAt(i);
            if (ch >= '\u4E00' && ch <= '\u9FFF') {
                return true;
            }
        }
        return false;
    }

    /**
     * 计算记忆强度
     */
    private BigDecimal calculateMemoryScore(BigDecimal currentScore, boolean isCorrect, int stage) {
        if (isCorrect) {
            // 阶段越高，正确增加越多
            BigDecimal increment;
            if (stage == 1) {
                increment = new BigDecimal("0.05");
            } else if (stage == 2) {
                increment = new BigDecimal("0.10");
            } else {
                increment = new BigDecimal("0.15");
            }
            BigDecimal newScore = currentScore.add(increment);
            return newScore.min(BigDecimal.ONE);
        } else {
            // 答错：减少 0.2
            BigDecimal newScore = currentScore.subtract(new BigDecimal("0.2"));
            return newScore.max(BigDecimal.ZERO);
        }
    }

    /**
     * 计算下次复习时间（SM-2 算法）
     */
    private LocalDateTime calculateNextReview(int reviewCount, boolean isCorrect) {
        if (!isCorrect) {
            return LocalDateTime.now().plusDays(1);
        }

        int intervalDays;
        if (reviewCount == 0) {
            intervalDays = 1;
        } else if (reviewCount == 1) {
            intervalDays = 3;
        } else if (reviewCount == 2) {
            intervalDays = 7;
        } else if (reviewCount == 3) {
            intervalDays = 14;
        } else {
            intervalDays = 30;
        }

        return LocalDateTime.now().plusDays(intervalDays);
    }
}
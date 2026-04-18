package com.zychen.backend.mapper;

import com.zychen.backend.entity.UserWord;
import org.apache.ibatis.annotations.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Mapper
public interface UserWordMapper {

    /**
     * 根据用户ID和单词ID查询（包含新字段）
     */
    @Select("SELECT id, user_id, word_id, status, study_stage, today_mastered, " +
            "review_count, next_review, memory_score, last_study_time, " +
            "create_time, update_time " +
            "FROM user_word WHERE user_id = #{userId} AND word_id = #{wordId}")
    UserWord findByUserIdAndWordId(@Param("userId") Long userId, @Param("wordId") Long wordId);


    /**
     * 获取当前学习队列（本组待学单词）：
     * - status = 0（学习中）
     * - today_mastered = 0（本词尚未完成三阶段）
     *
     * 不依赖 next_review 时间，避免因时区/时间边界导致第一阶段后“掉队列”。
     */
    @Select("SELECT id, user_id, word_id, status, study_stage, today_mastered, " +
            "review_count, next_review, memory_score, last_study_time, " +
            "create_time, update_time " +
            "FROM user_word " +
            "WHERE user_id = #{userId} " +
            "AND status = 0 " +
            "AND today_mastered = 0 " +
            "ORDER BY update_time ASC")
    List<UserWord> getTodayLearningWords(Long userId);

    /**
     * 获取“当前批次”学习队列（最多 limit 个）：
     * - 仅包含仍在学习中的词（status=0, today_mastered=0）
     * - 按创建顺序稳定分组，保证“这一组学完再进下一组”
     */
    @Select("SELECT id, user_id, word_id, status, study_stage, today_mastered, " +
            "review_count, next_review, memory_score, last_study_time, " +
            "create_time, update_time " +
            "FROM user_word " +
            "WHERE user_id = #{userId} " +
            "AND status = 0 " +
            "AND today_mastered = 0 " +
            "ORDER BY create_time ASC, id ASC " +
            "LIMIT #{limit}")
    List<UserWord> getCurrentBatchLearningWords(@Param("userId") Long userId, @Param("limit") Integer limit);

    /**
     * 统计全部待学习队列数量（不分批）
     */
    @Select("SELECT COUNT(*) FROM user_word " +
            "WHERE user_id = #{userId} " +
            "AND status = 0 " +
            "AND today_mastered = 0")
    int countAllLearningWords(Long userId);

    /**
     * 统计今日已完成单词数
     */
    @Select("SELECT COUNT(*) FROM user_word " +
            "WHERE user_id = #{userId} AND today_mastered = 1")
    int countTodayCompleted(Long userId);

    /**
     * 统计「待新学」数量：学习中、今日未完成三阶段、且尚未进入复习轮次（review_count = 0）。
     * 与 {@link #getCurrentBatchLearningWords} 中按新词拆分条件一致。
     */
    @Select("SELECT COUNT(*) FROM user_word " +
            "WHERE user_id = #{userId} " +
            "AND status = 0 " +
            "AND today_mastered = 0 " +
            "AND (review_count IS NULL OR review_count = 0)")
    int countPendingNewWords(Long userId);

    /**
     * 统计「可复习」池总量：学习中、今日未掌握、且已进入复习轮次（review_count > 0）。
     * 与 {@link #getReviewWords} 筛选条件一致（不限于本接口单次 LIMIT）。
     */
    @Select("SELECT COUNT(*) FROM user_word " +
            "WHERE user_id = #{userId} " +
            "AND status = 0 " +
            "AND today_mastered = 0 " +
            "AND review_count > 0")
    int countPendingReviewWords(Long userId);

    /**
     * 可复习单词数量（不改表结构，仅统计）：已进入间隔重复且 next_review 已到期。
     */
    @Select("SELECT COUNT(*) FROM user_word " +
            "WHERE user_id = #{userId} " +
            "AND status = 0 " +
            "AND review_count > 0 " +
            "AND next_review <= NOW()")
    int countReviewableWords(Long userId);

    /**
     * 统计“今日复习答错”的数量（仅复习词，且最后学习时间在今天）
     * 用于控制复习轮次：只有当前轮全对，才允许进入下一轮复习词。
     */
    @Select("SELECT COUNT(*) FROM user_word " +
            "WHERE user_id = #{userId} " +
            "AND review_count > 0 " +
            "AND today_mastered = 1 " +
            "AND status = 0 " +
            "AND last_study_time IS NOT NULL " +
            "AND DATE(last_study_time) = CURDATE()")
    int countTodayWrongReviewedWords(Long userId);

    /**
     * 获取用户复习词（保留旧接口兼容，按 review_count > 0 判定）
     */
    @Select("SELECT uw.id, uw.user_id, uw.word_id, uw.status, uw.study_stage, uw.today_mastered, " +
            "uw.review_count, uw.next_review, uw.memory_score, uw.last_study_time, " +
            "uw.create_time, uw.update_time " +
            "FROM user_word uw " +
            "WHERE uw.user_id = #{userId} " +
            "AND uw.status = 0 " +
            "AND uw.today_mastered = 0 " +
            "AND uw.review_count > 0 " +
            "ORDER BY uw.update_time ASC " +
            "LIMIT #{limit}")
    List<UserWord> getReviewWords(@Param("userId") Long userId, @Param("limit") Integer limit);

    /**
     * 获取“今日进行中的复习词”（本轮已开始但仍未答对的词）。
     * 用于实现：先锁定一组复习词，组内未全对前不放行下一组。
     */
    @Select("SELECT uw.id, uw.user_id, uw.word_id, uw.status, uw.study_stage, uw.today_mastered, " +
            "uw.review_count, uw.next_review, uw.memory_score, uw.last_study_time, " +
            "uw.create_time, uw.update_time " +
            "FROM user_word uw " +
            "WHERE uw.user_id = #{userId} " +
            "AND uw.status = 0 " +
            "AND uw.today_mastered = 0 " +
            "AND uw.review_count > 0 " +
            "AND uw.last_study_time IS NOT NULL " +
            "AND DATE(uw.last_study_time) = CURDATE() " +
            "ORDER BY uw.last_study_time ASC, uw.id ASC " +
            "LIMIT #{limit}")
    List<UserWord> getTodayInProgressReviewWords(@Param("userId") Long userId, @Param("limit") Integer limit);

    /**
     * 获取用户已学过的所有单词ID
     * 用于获取新词时排除
     */
    @Select("SELECT word_id FROM user_word WHERE user_id = #{userId}")
    List<Long> getLearnedWordIds(Long userId);

    /**
     * 获取生词本列表（完整 user_word 列，供业务层关联 word）
     */
    @Select("SELECT uw.id, uw.user_id, uw.word_id, uw.status, uw.study_stage, uw.today_mastered, " +
            "uw.review_count, uw.next_review, uw.memory_score, uw.last_study_time, " +
            "uw.create_time, uw.update_time " +
            "FROM user_word uw " +
            "WHERE uw.user_id = #{userId} AND uw.status = 2 " +
            "ORDER BY uw.create_time DESC " +
            "LIMIT #{offset}, #{size}")
    List<UserWord> getWordbook(@Param("userId") Long userId,
                               @Param("offset") Integer offset,
                               @Param("size") Integer size);

    /**
     * 获取生词本总数
     * 对应 api.yaml: /wordbook/list 分页需要
     */
    @Select("SELECT COUNT(*) FROM user_word WHERE user_id = #{userId} AND status = 2")
    int countWordbook(Long userId);

    /** 已加入学习的单词总数（user_word 行数） */
    @Select("SELECT COUNT(*) FROM user_word WHERE user_id = #{userId}")
    int countLearnedWords(Long userId);

    /** 已掌握（status=1） */
    @Select("SELECT COUNT(*) FROM user_word WHERE user_id = #{userId} AND status = 1")
    int countMasteredWords(Long userId);

    /** 待复习：学习中且已到复习时间 */
    @Select("SELECT COUNT(*) FROM user_word WHERE user_id = #{userId} AND status = 0 AND next_review <= NOW()")
    int countDueReview(Long userId);

    /**
     * 插入新学习记录（包含新字段）
     */
    @Insert("INSERT INTO user_word (user_id, word_id, status, study_stage, today_mastered, " +
            "review_count, next_review, memory_score, last_study_time) " +
            "VALUES (#{userId}, #{wordId}, #{status}, #{studyStage}, #{todayMastered}, " +
            "#{reviewCount}, #{nextReview}, #{memoryScore}, #{lastStudyTime})")
    @Options(useGeneratedKeys = true, keyProperty = "id")
    int insert(UserWord userWord);

    /**
     * 更新学习结果（渐进式学习版本）
     */
    @Update("UPDATE user_word SET status = #{status}, " +
            "study_stage = #{studyStage}, " +
            "today_mastered = #{todayMastered}, " +
            "review_count = #{reviewCount}, " +
            "next_review = #{nextReview}, " +
            "memory_score = #{memoryScore}, " +
            "last_study_time = #{lastStudyTime} " +
            "WHERE user_id = #{userId} AND word_id = #{wordId}")
    int updateAfterLearn(@Param("userId") Long userId,
                         @Param("wordId") Long wordId,
                         @Param("status") Integer status,
                         @Param("studyStage") Integer studyStage,
                         @Param("todayMastered") Integer todayMastered,
                         @Param("reviewCount") Integer reviewCount,
                         @Param("nextReview") LocalDateTime nextReview,
                         @Param("memoryScore") BigDecimal memoryScore,
                         @Param("lastStudyTime") LocalDateTime lastStudyTime);

    /**
     * 添加到生词本
     * 对应 api.yaml: /wordbook/add
     */
    @Update("UPDATE user_word SET status = 2 WHERE user_id = #{userId} AND word_id = #{wordId}")
    int addToWordbook(@Param("userId") Long userId, @Param("wordId") Long wordId);

    /**
     * 从生词本移除
     * 对应 api.yaml: /wordbook/remove/{wordId}
     */
    @Update("UPDATE user_word SET status = 0 WHERE user_id = #{userId} AND word_id = #{wordId}")
    int removeFromWordbook(@Param("userId") Long userId, @Param("wordId") Long wordId);

    /**
     * 检查单词是否在生词本中
     */
    @Select("SELECT COUNT(*) FROM user_word WHERE user_id = #{userId} " +
            "AND word_id = #{wordId} AND status = 2")
    int isInWordbook(@Param("userId") Long userId, @Param("wordId") Long wordId);
}
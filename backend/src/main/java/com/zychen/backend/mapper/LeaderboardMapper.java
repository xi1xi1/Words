package com.zychen.backend.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 排行榜查询。排名使用子查询实现，兼容 MySQL 5.7（无窗口函数）。
 */
@Mapper
public interface LeaderboardMapper {

    @Select("""
            SELECT u.id AS userId, u.username, u.avatar, u.total_score AS score,
                   (SELECT COUNT(*) FROM user u2 WHERE u2.total_score > u.total_score) + 1 AS rk
            FROM user u
            ORDER BY u.total_score DESC, u.id ASC
            LIMIT #{limit}
            """)
    List<LeaderboardRankRow> selectTopByTotalScore(@Param("limit") int limit);

    @Select("""
            SELECT rnk FROM (
                SELECT u.id AS id,
                       (SELECT COUNT(*) FROM user u2 WHERE u2.total_score > u.total_score) + 1 AS rnk
                FROM user u
            ) x WHERE id = #{userId}
            """)
    Integer selectUserRankByTotalScore(@Param("userId") Long userId);

    @Select("""
            SELECT u.id AS userId, u.username, u.avatar,
                   (COALESCE(sr.study_count, 0) + COALESCE(sr.review_count, 0)) AS score,
                   (SELECT COUNT(*) FROM user u2
                     LEFT JOIN study_record sr2 ON sr2.user_id = u2.id AND sr2.study_date = CURDATE()
                     WHERE (COALESCE(sr2.study_count, 0) + COALESCE(sr2.review_count, 0)) >
                           (COALESCE(sr.study_count, 0) + COALESCE(sr.review_count, 0))
                   ) + 1 AS rk
            FROM user u
            LEFT JOIN study_record sr ON sr.user_id = u.id AND sr.study_date = CURDATE()
            ORDER BY score DESC, u.id ASC
            LIMIT #{limit}
            """)
    List<LeaderboardRankRow> selectTopByDailyActivity(@Param("limit") int limit);

    @Select("""
            SELECT rnk FROM (
                SELECT u.id AS id,
                       (SELECT COUNT(*) FROM user u2
                         LEFT JOIN study_record sr2 ON sr2.user_id = u2.id AND sr2.study_date = CURDATE()
                         WHERE (COALESCE(sr2.study_count, 0) + COALESCE(sr2.review_count, 0)) >
                               (COALESCE(sr.study_count, 0) + COALESCE(sr.review_count, 0))
                       ) + 1 AS rnk
                FROM user u
                LEFT JOIN study_record sr ON sr.user_id = u.id AND sr.study_date = CURDATE()
            ) x WHERE id = #{userId}
            """)
    Integer selectUserRankByDailyActivity(@Param("userId") Long userId);

    @Select("""
            SELECT w.userId, w.username, w.avatar, w.weekScore AS score,
                   (SELECT COUNT(*) FROM (
                        SELECT u3.id AS uid,
                               COALESCE(SUM(sr3.study_count + sr3.review_count), 0) AS ws
                        FROM user u3
                        LEFT JOIN study_record sr3 ON sr3.user_id = u3.id
                          AND sr3.study_date >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
                          AND sr3.study_date <= CURDATE()
                        GROUP BY u3.id
                    ) z WHERE z.ws > w.weekScore
                   ) + 1 AS rk
            FROM (
                SELECT u.id AS userId, u.username, u.avatar,
                       COALESCE(SUM(sr.study_count + sr.review_count), 0) AS weekScore
                FROM user u
                LEFT JOIN study_record sr ON sr.user_id = u.id
                    AND sr.study_date >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
                    AND sr.study_date <= CURDATE()
                GROUP BY u.id, u.username, u.avatar
            ) w
            ORDER BY w.weekScore DESC, w.userId ASC
            LIMIT #{limit}
            """)
    List<LeaderboardRankRow> selectTopByWeeklyActivity(@Param("limit") int limit);

    @Select("""
            SELECT rnk FROM (
                SELECT s.id,
                       (SELECT COUNT(*) FROM (
                            SELECT u3.id AS uid,
                                   COALESCE(SUM(sr3.study_count + sr3.review_count), 0) AS ws
                            FROM user u3
                            LEFT JOIN study_record sr3 ON sr3.user_id = u3.id
                              AND sr3.study_date >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
                              AND sr3.study_date <= CURDATE()
                            GROUP BY u3.id
                        ) z2 WHERE z2.ws > s.weekScore
                       ) + 1 AS rnk
                FROM (
                    SELECT u.id AS id, COALESCE(SUM(sr.study_count + sr.review_count), 0) AS weekScore
                    FROM user u
                    LEFT JOIN study_record sr ON sr.user_id = u.id
                        AND sr.study_date >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
                        AND sr.study_date <= CURDATE()
                    GROUP BY u.id
                ) s
            ) x WHERE id = #{userId}
            """)
    Integer selectUserRankByWeeklyActivity(@Param("userId") Long userId);
}

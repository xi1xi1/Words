package com.zychen.backend.mapper;

import com.zychen.backend.entity.Word;
import org.apache.ibatis.annotations.*;

import java.util.List;

@Mapper
public interface WordMapper {

    /**
     * 根据ID查询单词
     */
    @Select("SELECT id, word, meaning, phonetic, example, create_time " +
            "FROM word WHERE id = #{id}")
    Word findById(Long id);

    /**
     * 根据单词名称查询
     */
    @Select("SELECT id, word, meaning, phonetic, example, create_time " +
            "FROM word WHERE word = #{word}")
    Word findByWord(String word);

    /**
     * 搜索单词（模糊匹配）
     */
    @Select("SELECT id, word, meaning, phonetic, example, create_time " +
            "FROM word WHERE word LIKE CONCAT('%', #{keyword}, '%') " +
            "LIMIT #{offset}, #{size}")
    List<Word> search(@Param("keyword") String keyword,
                      @Param("offset") Integer offset,
                      @Param("size") Integer size);

    /**
     * 搜索单词总数
     */
    @Select("SELECT COUNT(*) FROM word WHERE word LIKE CONCAT('%', #{keyword}, '%')")
    int countByKeyword(String keyword);

    /**
     * 统计词库总单词数
     */
    @Select("SELECT COUNT(*) FROM word")
    int countAllWords();

    /**
     * 随机获取指定数量的单词
     */
    @Select("SELECT id, word, meaning, phonetic, example, create_time " +
            "FROM word ORDER BY RAND() LIMIT #{limit}")
    List<Word> getRandomWords(int limit);

    /**
     * 获取今日推荐单词（按ID范围或最新添加）
     */
    @Select("SELECT id, word, meaning, phonetic, example, create_time " +
            "FROM word ORDER BY id DESC LIMIT #{limit}")
    List<Word> getLatestWords(int limit);

    /**
     * 批量获取单词（根据ID列表）
     */
    @Select("<script>" +
            "SELECT id, word, meaning, phonetic, example, create_time " +
            "FROM word WHERE id IN " +
            "<foreach collection='ids' item='id' open='(' separator=',' close=')'>" +
            "#{id}" +
            "</foreach>" +
            "</script>")
    List<Word> findByIds(@Param("ids") List<Long> ids);

    /**
     * 获取最新单词（排除已学过的单词ID列表）
     * 用于获取新词时排除已学单词
     */
    @Select("<script>" +
            "SELECT id, word, meaning, phonetic, example, create_time " +
            "FROM word " +
            "WHERE id NOT IN " +
            "<foreach collection='excludeIds' item='id' open='(' separator=',' close=')'>" +
            "#{id}" +
            "</foreach> " +
            "ORDER BY id DESC " +
            "LIMIT #{limit}" +
            "</script>")
    List<com.zychen.backend.entity.Word> getLatestWordsExclude(@Param("excludeIds") List<Long> excludeIds,
                                                               @Param("limit") int limit);



    /**
     * 统计新词数量（排除已学过的）
     */
    @Select("<script>" +
            "SELECT COUNT(*) FROM word " +
            "WHERE id NOT IN (SELECT word_id FROM user_word WHERE user_id = #{userId}) " +
            "</script>")
    int countNewWords(Long userId);

    /**
     * 随机获取单词（排除指定ID）
     */
    @Select("SELECT id, word, meaning, phonetic, example, create_time " +
            "FROM word " +
            "WHERE id != #{excludeId} " +
            "ORDER BY RAND() " +
            "LIMIT #{limit}")
    List<com.zychen.backend.entity.Word> getRandomWordsExclude(@Param("excludeId") Long excludeId,
                                                               @Param("limit") int limit);

    /**
     * 更新单词例句（JSON 数组字符串）
     */
    @Update("UPDATE word SET example = #{example} WHERE id = #{wordId}")
    int updateExample(@Param("wordId") Long wordId, @Param("example") String example);

}
package com.zychen.backend.mapper;

import com.zychen.backend.entity.User;
import org.apache.ibatis.annotations.*;

@Mapper
public interface UserMapper {

    /**
     * 根据用户名查询用户
     */
    @Select("SELECT id, username, password, avatar, email, total_score, level, create_time, update_time " +
            "FROM user WHERE username = #{username}")
    User findByUsername(String username);

    /**
     * 根据ID查询用户
     */
    @Select("SELECT id, username, password, avatar, email, total_score, level, create_time, update_time " +
            "FROM user WHERE id = #{id}")
    User findById(Long id);

    /**
     * 插入新用户
     */
    @Insert("INSERT INTO user (username, password, email, avatar, total_score, level) " +
            "VALUES (#{username}, #{password}, #{email}, #{avatar}, #{totalScore}, #{level})")
    @Options(useGeneratedKeys = true, keyProperty = "id")
    int insert(User user);

    /**
     * 更新用户积分
     */
    @Update("UPDATE user SET total_score = total_score + #{score} WHERE id = #{id}")
    int addScore(@Param("id") Long id, @Param("score") Integer score);

    /**
     * 更新用户头像
     */
    @Update("UPDATE user SET avatar = #{avatar} WHERE id = #{id}")
    int updateAvatar(@Param("id") Long id, @Param("avatar") String avatar);
}
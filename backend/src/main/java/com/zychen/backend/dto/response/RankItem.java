package com.zychen.backend.dto.response;

import lombok.Data;

@Data
public class RankItem {

    private Integer rank;        // 排名
    private Long userId;         // 用户ID
    private String username;     // 用户名
    private String avatar;       // 头像URL
    private Integer totalScore;  // 总积分
}
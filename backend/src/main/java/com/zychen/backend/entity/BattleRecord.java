package com.zychen.backend.entity;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class BattleRecord {
    private Long id;
    private Long userId;
    private Integer levelType;   // 关卡等级：1初级 2中级 3高级
    private Integer score;
    private Integer correctCount;
    private Integer totalCount;
    private Integer duration;    // 耗时（秒），可为空
    private String details;      // 数据库 JSON，Java 用 String 接收
    private LocalDateTime createTime;
}

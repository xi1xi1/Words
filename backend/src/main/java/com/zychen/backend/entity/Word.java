package com.zychen.backend.entity;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class Word {
    private Long id;
    private String word;
    private String meaning;      // 数据库是 JSON 类型，Java 中用 String 接收
    private String phonetic;
    private String example;      // 数据库是 JSON 类型，Java 中用 String 接收
    private LocalDateTime createTime;
}
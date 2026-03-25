package com.zychen.backend.entity;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class User {
    private Long id;
    private String username;
    private String password;
    private String avatar;
    private String email;
    private Integer totalScore;
    private Integer level;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}

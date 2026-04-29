package com.zychen.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
public class UserInfoResponse {

    private Long id;
    private String username;
    private String avatar;
    private Integer totalScore;
    private Integer level;
    private LocalDateTime createTime;
}
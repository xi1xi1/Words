package com.zychen.backend.dto.response;

import lombok.Data;
import java.util.List;

@Data
public class ChallengeStartResponse {

    private String challengeId;           // 闯关ID
    private List<ChallengeQuestion> questions;  // 题目列表
    private Integer timeLimit;            // 限时（秒）
}
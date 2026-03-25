package com.zychen.backend.dto.response;

import lombok.Data;
import java.util.List;

@Data
public class ChallengeQuestion {

    private Long id;
    private String word;
    private List<String> options;
    private Integer correctIndex;
}
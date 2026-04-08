package com.zychen.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChallengeLevelRankItem {

    private Integer rank;
    private Long userId;
    private String username;
    private String avatar;
    private Integer bestScore;
}

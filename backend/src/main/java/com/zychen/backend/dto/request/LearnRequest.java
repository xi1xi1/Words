package com.zychen.backend.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class LearnRequest {

    @NotNull(message = "单词ID不能为空")
    private Long wordId;

    @NotNull(message = "是否正确不能为空")
    private Boolean isCorrect;

    @NotNull(message = "学习阶段不能为空")
    private Integer stage;  // 1-选义 2-选例 3-认词

}
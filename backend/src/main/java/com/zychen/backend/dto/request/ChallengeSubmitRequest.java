package com.zychen.backend.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

@Data
public class ChallengeSubmitRequest {

    @NotBlank(message = "闯关ID不能为空")
    private String challengeId;

    @NotNull(message = "关卡等级不能为空")
    @Min(value = 1, message = "关卡等级最小为1")
    @Max(value = 3, message = "关卡等级最大为3")
    private Integer levelType;

    @NotEmpty(message = "答案列表不能为空")
    private List<AnswerItem> answers;

    @Data
    public static class AnswerItem {
        @NotNull(message = "题目ID不能为空")
        private Long questionId;

        @NotNull(message = "选项索引不能为空")
        private Integer selectedIndex;

        private Integer timeSpent;  // 答题耗时（秒）
    }
}
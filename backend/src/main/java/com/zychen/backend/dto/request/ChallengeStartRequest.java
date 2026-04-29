package com.zychen.backend.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ChallengeStartRequest {

    @NotNull(message = "关卡等级不能为空")
    @Min(value = 1, message = "关卡等级最小为1")
    @Max(value = 3, message = "关卡等级最大为3")
    private Integer levelType;  // 1-初级场 2-中级场 3-高级场
}
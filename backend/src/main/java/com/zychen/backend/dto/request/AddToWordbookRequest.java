package com.zychen.backend.dto.request;


import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class AddToWordbookRequest {

    @NotNull(message = "单词ID不能为空")
    private Long wordId;
}
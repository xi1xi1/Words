package com.zychen.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MemoryHintBlock {
    private String title;
    private String content;
    private String explanation;
}

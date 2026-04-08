package com.zychen.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class NextWordInfo {
    private Long wordId;
    private String word;
    private List<String> meaning;
    private String phonetic;
    private Integer stage;      // 1-选义 2-选例 3-认词
    private List<String> options;  // 阶段1时使用
    private String example;     // 阶段2时使用
}
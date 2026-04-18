package com.zychen.backend.dto.response;

import lombok.Data;

@Data
public class AIMemoryContent {
    private String word;
    private String meaning;
    private MemoryHintBlock homophonic;
    private MemoryHintBlock morpheme;
    private MemoryHintBlock story;
    private String summary;
    private String notes;
}

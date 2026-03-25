package com.zychen.backend.dto.response;

import lombok.Data;
import java.util.List;

@Data
public class Word {
    private Long id;
    private String word;
    private List<String> meaning;
    private String phonetic;
    private List<String> example;
}
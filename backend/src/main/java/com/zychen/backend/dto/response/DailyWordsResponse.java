package com.zychen.backend.dto.response;

import lombok.Data;
import java.util.List;

@Data
public class DailyWordsResponse {

    private List<Word> newWords;
    private List<Word> reviewWords;
    private Integer total;
}
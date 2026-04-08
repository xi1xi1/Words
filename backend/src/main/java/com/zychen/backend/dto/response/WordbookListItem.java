package com.zychen.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WordbookListItem {

    /** user_word 主键 */
    private Long id;
    private Long wordId;
    private String word;
    private List<String> meaning;
    private String phonetic;
    private List<String> example;
    /** 加入生词本时间（user_word.create_time） */
    private LocalDateTime addTime;
}

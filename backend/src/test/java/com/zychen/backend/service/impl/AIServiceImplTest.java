package com.zychen.backend.service.impl;

import com.zychen.backend.dto.response.AIMemoryContent;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zychen.backend.entity.Word;
import com.zychen.backend.mapper.WordMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AIServiceImplTest {

    @Mock
    private WordMapper wordMapper;

    @Mock
    private ObjectMapper objectMapper;

    @Spy
    @InjectMocks
    private AIServiceImpl aiService;

    @BeforeEach
    void setUp() {
        // 默认不配置 key/endpoint，避免走真实 HTTP
        ReflectionTestUtils.setField(aiService, "arkBaseUrl", "http://example.invalid");
        ReflectionTestUtils.setField(aiService, "arkApiKey", "");
        ReflectionTestUtils.setField(aiService, "endpointId", "");
    }

    @Test
    void generateExample_missingConfig_returnsNull() {
        assertNull(aiService.generateExample("abandon", "v. 放弃"));
    }

    @Test
    void generateMemoryContent_missingConfig_returnsNull() {
        assertNull(aiService.generateMemoryContent("abandon", "v. 放弃"));
    }

    @Test
    void generateAndPersistExample_wordIdNull_noInteraction() {
        aiService.generateAndPersistExample(null, "abandon", "v. 放弃");
        verifyNoInteractions(wordMapper);
    }

    @Test
    void generateAndPersistExample_wordBlank_noInteraction() {
        aiService.generateAndPersistExample(1L, "   ", "v. 放弃");
        verifyNoInteractions(wordMapper);
    }

    @Test
    void generateAndPersistExample_sentenceNull_noInteraction() {
        doReturn(null).when(aiService).generateExample(anyString(), anyString());

        aiService.generateAndPersistExample(1L, "abandon", "v. 放弃");
        verifyNoInteractions(wordMapper);
    }

    @Test
    void generateAndPersistExample_wordNotFound_doesNotUpdate() {
        doReturn("A short sentence.").when(aiService).generateExample(anyString(), anyString());
        when(wordMapper.findById(1L)).thenReturn(null);

        aiService.generateAndPersistExample(1L, "abandon", "v. 放弃");

        verify(wordMapper).findById(1L);
        verify(wordMapper, never()).updateExample(any(), any());
    }

    @Test
    void generateAndPersistExample_existingExampleMergeAndUpdate() {
        doReturn("He abandoned his plan.").when(aiService).generateExample(anyString(), anyString());

        Word w = new Word();
        w.setId(1L);
        w.setExample("[\"Old example.\"]");
        when(wordMapper.findById(1L)).thenReturn(w);
        when(wordMapper.updateExample(eq(1L), anyString())).thenReturn(1);

        // Let mergeExampleJson use the real ObjectMapper by swapping in a real instance for this test.
        ReflectionTestUtils.setField(aiService, "objectMapper", new ObjectMapper());

        aiService.generateAndPersistExample(1L, "abandon", "v. 放弃");

        verify(wordMapper).updateExample(eq(1L), eq("[\"Old example.\",\"He abandoned his plan.\"]"));
    }

    @Test
    void generateAndPersistExample_duplicateSentence_notAppendedTwice() {
        doReturn("He abandoned his plan.").when(aiService).generateExample(anyString(), anyString());

        Word w = new Word();
        w.setId(1L);
        w.setExample("[\"He abandoned his plan.\"]");
        when(wordMapper.findById(1L)).thenReturn(w);
        when(wordMapper.updateExample(eq(1L), anyString())).thenReturn(1);
        ReflectionTestUtils.setField(aiService, "objectMapper", new ObjectMapper());

        aiService.generateAndPersistExample(1L, "abandon", "v. 放弃");

        verify(wordMapper).updateExample(eq(1L), eq("[\"He abandoned his plan.\"]"));
    }

    @Test
    void generateAndPersistExample_invalidExistingJson_resetsToSingleSentence() {
        doReturn("Fresh sentence.").when(aiService).generateExample(anyString(), anyString());

        Word w = new Word();
        w.setId(1L);
        w.setExample("not-json");
        when(wordMapper.findById(1L)).thenReturn(w);
        when(wordMapper.updateExample(eq(1L), anyString())).thenReturn(1);
        ReflectionTestUtils.setField(aiService, "objectMapper", new ObjectMapper());

        aiService.generateAndPersistExample(1L, "abandon", "v. 放弃");

        verify(wordMapper).updateExample(eq(1L), eq("[\"Fresh sentence.\"]"));
    }

    @Test
    void normalizeLikelyJson_extraText_extractsObjectRange() {
        String raw = "Result: {\"summary\":\"ok\"} trailing";
        String normalized = invokeNormalizeLikelyJson(raw);
        assertEquals("{\"summary\":\"ok\"}", normalized);
    }

    @Test
    void repairCommonJsonIssues_noTrailingComma_keepsOriginal() {
        String src = "{\"a\":1,\"b\":[1,2]}";
        assertEquals(src, invokeRepairCommonJsonIssues(src));
    }

    @Test
    void normalizeLikelyJson_stripsCodeFenceAndExtractsObject() {
        String raw = "```json\n{\"summary\":\"ok\",\"notes\":\"n\"}\n```";
        String normalized = invokeNormalizeLikelyJson(raw);
        assertEquals("{\"summary\":\"ok\",\"notes\":\"n\"}", normalized);
    }

    @Test
    void repairCommonJsonIssues_removesTrailingCommas() {
        String fixed = invokeRepairCommonJsonIssues("{\"a\":1,}");
        assertEquals("{\"a\":1}", fixed);
        assertEquals("[1,2]", invokeRepairCommonJsonIssues("[1,2,]"));
    }

    @Test
    void extractContent_invalidJson_returnsNull() {
        ReflectionTestUtils.setField(aiService, "objectMapper", new ObjectMapper());
        String result = invokeExtractContent("not-json");
        assertNull(result);
    }

    @Test
    void extractContent_noChoicesArray_returnsNull() {
        ReflectionTestUtils.setField(aiService, "objectMapper", new ObjectMapper());
        String result = invokeExtractContent("{\"id\":\"x\"}");
        assertNull(result);
    }

    @Test
    void parseMemoryContent_blankSummary_fallsBackToWordAndMeaning() {
        ReflectionTestUtils.setField(aiService, "objectMapper", new ObjectMapper());
        AIMemoryContent out = invokeParseMemoryContent(
                "{\"homophonic\":null,\"morpheme\":null,\"story\":null,\"summary\":\"\",\"notes\":\"n\"}",
                "abandon",
                "v. 放弃");
        assertNotNull(out);
        assertEquals("abandon：v. 放弃", out.getSummary());
    }

    @Test
    void parseMemoryContent_invalidJson_returnsNull() {
        ReflectionTestUtils.setField(aiService, "objectMapper", new ObjectMapper());
        AIMemoryContent out = invokeParseMemoryContent("oops", "abandon", "v. 放弃");
        assertNull(out);
    }

    @Test
    void mergeExampleJson_whenSerializationFails_fallsBackToEscapedJsonArray() throws Exception {
        ReflectionTestUtils.setField(aiService, "objectMapper", objectMapper);
        when(objectMapper.writeValueAsString(any())).thenThrow(new RuntimeException("serialize fail"));

        String merged = invokeMergeExampleJson(null, "He said \"hi\".");

        assertEquals("[\"He said \\\"hi\\\".\"]", merged);
    }

    private static String invokeNormalizeLikelyJson(String input) {
        return (String) ReflectionTestUtils.invokeMethod(AIServiceImpl.class, "normalizeLikelyJson", input);
    }

    private static String invokeRepairCommonJsonIssues(String input) {
        return (String) ReflectionTestUtils.invokeMethod(AIServiceImpl.class, "repairCommonJsonIssues", input);
    }

    private String invokeExtractContent(String input) {
        return (String) ReflectionTestUtils.invokeMethod(aiService, "extractContent", input);
    }

    private AIMemoryContent invokeParseMemoryContent(String jsonContent, String word, String meaning) {
        return (AIMemoryContent) ReflectionTestUtils.invokeMethod(aiService, "parseMemoryContent", jsonContent, word, meaning);
    }

    private String invokeMergeExampleJson(String existingJson, String newSentence) {
        return (String) ReflectionTestUtils.invokeMethod(aiService, "mergeExampleJson", existingJson, newSentence);
    }
}


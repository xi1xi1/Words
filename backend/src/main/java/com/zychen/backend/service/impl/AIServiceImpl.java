package com.zychen.backend.service.impl;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.zychen.backend.entity.Word;
import com.zychen.backend.mapper.WordMapper;
import com.zychen.backend.service.AIService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;

@Slf4j
@Service
@RequiredArgsConstructor
public class AIServiceImpl implements AIService {

    private static final MediaType JSON = MediaType.get("application/json; charset=utf-8");

    private final WordMapper wordMapper;
    private final ObjectMapper objectMapper;

    @Value("${ark.base-url}")
    private String arkBaseUrl;

    @Value("${ark.api-key}")
    private String arkApiKey;

    @Value("${ark.endpoint-id}")
    private String endpointId;

    private final OkHttpClient httpClient = new OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(60, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .build();

    @Override
    public String generateExample(String word, String meaning) {
        if (!StringUtils.hasText(arkApiKey) || !StringUtils.hasText(endpointId)) {
            log.warn("ark.api-key 或 ark.endpoint-id 未配置");
            return null;
        }
        String prompt = buildPrompt(word, meaning);
        ObjectNode body = objectMapper.createObjectNode();
        body.put("model", endpointId);
        ArrayNode messages = body.putArray("messages");
        ObjectNode sys = messages.addObject();
        sys.put("role", "system");
        sys.put("content",
                "You help English learners. Reply with one natural English example sentence only, no translation, no quotes, no numbering.");
        ObjectNode userMsg = messages.addObject();
        userMsg.put("role", "user");
        userMsg.put("content", prompt);
        body.put("max_tokens", 128);

        String json;
        try {
            json = objectMapper.writeValueAsString(body);
        } catch (Exception e) {
            log.error("序列化方舟请求体失败", e);
            return null;
        }

        Request request = new Request.Builder()
                .url(arkBaseUrl)
                .header("Authorization", "Bearer " + arkApiKey.trim())
                .post(RequestBody.create(json, JSON))
                .build();

        try (Response response = httpClient.newCall(request).execute()) {
            String respBody = response.body() != null ? response.body().string() : "";
            if (!response.isSuccessful()) {
                log.warn("方舟调用失败: status={}, body={}", response.code(), truncate(respBody, 500));
                return null;
            }
            return extractContent(respBody);
        } catch (IOException e) {
            log.error("方舟 HTTP 请求异常", e);
            return null;
        }
    }

    @Override
    @Async
    public void generateAndPersistExample(Long wordId, String word, String meaning) {
        if (wordId == null || !StringUtils.hasText(word)) {
            return;
        }
        String sentence = generateExample(word, meaning);
        if (!StringUtils.hasText(sentence)) {
            return;
        }
        sentence = sentence.trim();
        Word w = wordMapper.findById(wordId);
        if (w == null) {
            log.warn("异步写例句时单词已不存在: wordId={}", wordId);
            return;
        }
        String merged = mergeExampleJson(w.getExample(), sentence);
        int n = wordMapper.updateExample(wordId, merged);
        if (n > 0) {
            log.info("已更新单词例句: wordId={}, preview={}", wordId, truncate(sentence, 80));
        }
    }

    private static String buildPrompt(String word, String meaning) {
        String m = meaning == null ? "" : meaning.trim();
        return "English word: \"" + word + "\". Meaning (may be JSON): " + m
                + ". Write ONE short natural English sentence using this word. Output only the sentence.";
    }

    private String extractContent(String respBody) {
        try {
            JsonNode root = objectMapper.readTree(respBody);
            JsonNode choices = root.path("choices");
            if (!choices.isArray() || choices.isEmpty()) {
                return null;
            }
            String text = choices.get(0).path("message").path("content").asText("");
            text = text.trim();
            if (text.startsWith("\"") && text.endsWith("\"") && text.length() >= 2) {
                text = text.substring(1, text.length() - 1).trim();
            }
            return text.isEmpty() ? null : text;
        } catch (Exception e) {
            log.warn("解析方舟响应失败: {}", truncate(respBody, 300));
            return null;
        }
    }

    private String mergeExampleJson(String existingJson, String newSentence) {
        List<String> list = new ArrayList<>();
        if (StringUtils.hasText(existingJson)) {
            try {
                List<String> parsed = objectMapper.readValue(existingJson, new TypeReference<List<String>>() {});
                if (parsed != null) {
                    list.addAll(parsed);
                }
            } catch (Exception e) {
                log.debug("原 example 非数组 JSON，将重置为仅含新例句: {}", e.getMessage());
            }
        }
        boolean dup = list.stream().anyMatch(s -> s != null && s.trim().equalsIgnoreCase(newSentence.trim()));
        if (!dup) {
            list.add(newSentence);
        }
        try {
            return objectMapper.writeValueAsString(list);
        } catch (Exception e) {
            log.error("序列化 example 失败", e);
            try {
                return objectMapper.writeValueAsString(List.of(newSentence));
            } catch (Exception e2) {
                return "[\"" + newSentence.replace("\"", "\\\"") + "\"]";
            }
        }
    }

    private static String truncate(String s, int max) {
        if (s == null) {
            return "";
        }
        return s.length() <= max ? s : s.substring(0, max) + "...";
    }
}

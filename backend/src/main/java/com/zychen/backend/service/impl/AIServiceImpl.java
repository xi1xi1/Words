package com.zychen.backend.service.impl;

import com.zychen.backend.dto.response.AIMemoryContent;
import com.zychen.backend.dto.response.MemoryHintBlock;
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
        JsonNode root = callArk(buildExampleSystemPrompt(), buildPrompt(word, meaning), 128);
        if (root == null) {
            return null;
        }
        return extractContent(root.toString());
    }

    @Override
    public AIMemoryContent generateMemoryContent(String word, String meaning) {
        // 512 容易让模型输出 JSON 被截断，导致解析失败；适当提高上限并要求更短的字段。
        JsonNode root = callArk(buildMemorySystemPrompt(), buildMemoryUserPrompt(word, meaning), 768);
        if (root == null) {
            return null;
        }
        String content = extractContent(root.toString());
        if (!StringUtils.hasText(content)) {
            return null;
        }
        String normalized = normalizeLikelyJson(content);
        String repaired = repairCommonJsonIssues(normalized);
        return parseMemoryContent(repaired, word, meaning);
    }

    private JsonNode callArk(String systemPrompt, String userPrompt, int maxTokens) {
        if (!StringUtils.hasText(arkApiKey) || !StringUtils.hasText(endpointId)) {
            log.warn("ark.api-key 或 ark.endpoint-id 未配置");
            return null;
        }
        ObjectNode body = objectMapper.createObjectNode();
        body.put("model", endpointId);
        ArrayNode messages = body.putArray("messages");
        ObjectNode sys = messages.addObject();
        sys.put("role", "system");
        sys.put("content", systemPrompt);
        ObjectNode userMsg = messages.addObject();
        userMsg.put("role", "user");
        userMsg.put("content", userPrompt);
        body.put("max_tokens", maxTokens);

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
            return objectMapper.readTree(respBody);
        } catch (IOException e) {
            log.error("方舟 HTTP 请求异常", e);
            return null;
        } catch (Exception e) {
            log.warn("方舟响应JSON解析失败");
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

    private static String buildExampleSystemPrompt() {
        return "You help English learners. Reply with one natural English example sentence only, no translation, no quotes, no numbering.";
    }

    private static String buildMemorySystemPrompt() {
        return "You are an English memory coach for Chinese students. "
                + "Return ONE strict JSON object only. No markdown, no ``` fences, no extra text. "
                + "Keys must be exactly: homophonic, morpheme, story, summary, notes. "
                + "homophonic/morpheme/story is either null or an object {\"title\",\"content\",\"explanation\"}. "
                + "Keep each string short (<=40 Chinese characters). "
                + "summary must be a non-empty Chinese sentence.";
    }

    private static String buildMemoryUserPrompt(String word, String meaning) {
        String m = meaning == null ? "" : meaning.trim();
        return "Word: " + word + "\n"
                + "Meaning: " + m + "\n"
                + "Generate Chinese mnemonic hints. "
                + "If some hint type is unsuitable, set it to null. "
                + "Output JSON only.";
    }

    private AIMemoryContent parseMemoryContent(String jsonContent, String word, String meaning) {
        try {
            JsonNode node = objectMapper.readTree(jsonContent);
            AIMemoryContent out = new AIMemoryContent();
            out.setWord(word);
            out.setMeaning(meaning == null ? "" : meaning);
            out.setHomophonic(parseHint(node.path("homophonic")));
            out.setMorpheme(parseHint(node.path("morpheme")));
            out.setStory(parseHint(node.path("story")));
            out.setSummary(node.path("summary").asText(""));
            out.setNotes(node.path("notes").asText(""));
            if (!StringUtils.hasText(out.getSummary())) {
                out.setSummary(word + "：" + out.getMeaning());
            }
            return out;
        } catch (Exception e) {
            log.warn("解析联想记忆JSON失败: {}", truncate(jsonContent, 300), e);
            return null;
        }
    }

    /**
     * 模型有时会返回 ```json ... ``` 或在 JSON 前后加说明文字。
     * 这里尽量把内容规范化为一个可解析的 JSON 对象字符串。
     */
    private static String normalizeLikelyJson(String content) {
        if (content == null) {
            return null;
        }
        String s = content.trim();
        if (s.isEmpty()) {
            return s;
        }

        // Strip markdown code fences if present
        // e.g. ```json\n{...}\n```
        if (s.startsWith("```")) {
            int firstNewline = s.indexOf('\n');
            if (firstNewline >= 0) {
                s = s.substring(firstNewline + 1).trim();
            }
            if (s.endsWith("```")) {
                s = s.substring(0, s.length() - 3).trim();
            }
        }

        // If there's extra text, extract the largest {...} block
        int start = s.indexOf('{');
        int end = s.lastIndexOf('}');
        if (start >= 0 && end > start) {
            return s.substring(start, end + 1).trim();
        }
        return s;
    }

    /**
     * 修复常见 JSON 小问题（不保证覆盖所有情况）：
     * - 末尾多余逗号：{ "a": 1, } / [1,2,]
     */
    private static String repairCommonJsonIssues(String content) {
        if (content == null) {
            return null;
        }
        String s = content.trim();
        if (s.isEmpty()) {
            return s;
        }
        // remove trailing commas before } or ]
        // e.g. {"a":1,} -> {"a":1}
        //      [1,2,] -> [1,2]
        s = s.replaceAll(",\\s*([}\\]])", "$1");
        return s;
    }

    private MemoryHintBlock parseHint(JsonNode node) {
        if (node == null || node.isNull() || !node.isObject()) {
            return null;
        }
        String title = node.path("title").asText("");
        String content = node.path("content").asText("");
        String explanation = node.path("explanation").asText("");
        if (!StringUtils.hasText(title) || !StringUtils.hasText(content) || !StringUtils.hasText(explanation)) {
            return null;
        }
        return new MemoryHintBlock(title, content, explanation);
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

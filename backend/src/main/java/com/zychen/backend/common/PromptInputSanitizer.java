package com.zychen.backend.common;

import java.util.regex.Pattern;

/**
 * 进入大模型前的提示词输入净化与简单注入短语弱化。
 * <p>
 * 仅用于构造发往方舟的请求内容，不改变业务层返回给客户端的实体字段（仍使用库表原始数据）。
 */
public final class PromptInputSanitizer {

    /** 词条拼进 prompt 时的长度上限，防止异常长字段撑爆上下文。 */
    private static final int MAX_WORD_LEN = 256;
    /** 释义拼进 prompt 时的长度上限。 */
    private static final int MAX_MEANING_LEN = 8000;

    /**
     * 常见英文指令劫持短语（不区分大小写）。命中则移除匹配片段，其余文本保留。
     */
    private static final Pattern INJECTION_PHRASES = Pattern.compile(
            "(?i)(ignore\\s+(the\\s+)?(previous|above)\\s+instructions?|"
                    + "disregard\\s+(the\\s+)?(above|prior)|"
                    + "forget\\s+(all\\s+)?(previous|prior)\\s+instructions?|"
                    + "\\bnew\\s+instructions\\s*:\\s*|"
                    + "(?m)^\\s*system\\s*:\\s*|"
                    + "(?m)^\\s*assistant\\s*:\\s*|"
                    + "you\\s+are\\s+now\\s+(a\\s+)?)");

    private PromptInputSanitizer() {
    }

    public static String sanitizeWord(String word) {
        if (word == null) {
            return "";
        }
        String s = stripDangerousControls(word.trim());
        // 避免打断外层英文模板中的双引号包裹
        s = s.replace('"', '\'').replace('\\', '/');
        s = truncateUtf16(s, MAX_WORD_LEN);
        return stripInjectionPhrases(s).trim();
    }

    public static String sanitizeMeaning(String meaning) {
        if (meaning == null) {
            return "";
        }
        String s = stripDangerousControls(meaning.trim());
        s = truncateUtf16(s, MAX_MEANING_LEN);
        return stripInjectionPhrases(s).trim();
    }

    private static String stripDangerousControls(String s) {
        StringBuilder sb = new StringBuilder(s.length());
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (c == '\n' || c == '\r' || c == '\t' || !Character.isISOControl(c)) {
                sb.append(c);
            }
        }
        return sb.toString();
    }

    private static String truncateUtf16(String s, int maxChars) {
        if (s.length() <= maxChars) {
            return s;
        }
        return s.substring(0, maxChars);
    }

    private static String stripInjectionPhrases(String s) {
        return INJECTION_PHRASES.matcher(s).replaceAll("");
    }
}

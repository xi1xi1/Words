package com.zychen.backend.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zychen.backend.config.JwtUtil;
import com.zychen.backend.dto.request.ChallengeStartRequest;
import com.zychen.backend.dto.request.ChallengeSubmitRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.jdbc.Sql;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Sql(scripts = "/sql/challenge-test-data.sql", executionPhase = Sql.ExecutionPhase.BEFORE_TEST_CLASS)
public class ChallengeControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JwtUtil jwtUtil;

    private String bearerToken;

    @BeforeEach
    void setUp() {
        bearerToken = "Bearer " + jwtUtil.generateToken(1L, "jwt_challenge_user");
    }

    /**
     * 测试1：开始闯关成功
     */
    @Test
    void startChallenge_success() throws Exception {
        ChallengeStartRequest request = new ChallengeStartRequest();
        request.setLevelType(1);

        mockMvc.perform(post("/api/challenge/start")
                        .header("Authorization", bearerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("success"))
                .andExpect(jsonPath("$.data.challengeId").exists())
                .andExpect(jsonPath("$.data.questions").isArray())
                .andExpect(jsonPath("$.data.timeLimit").exists());
    }

    /**
     * 测试2：开始闯关失败 - 缺少 levelType
     */
    @Test
    void startChallenge_failed_missing_level() throws Exception {
        String request = "{}";  // 空对象

        mockMvc.perform(post("/api/challenge/start")
                        .header("Authorization", bearerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(request))
                .andExpect(status().isBadRequest());
    }

    /**
     * 测试3：开始闯关失败 - levelType 超出范围
     */
    @Test
    void startChallenge_failed_level_out_of_range() throws Exception {
        ChallengeStartRequest request = new ChallengeStartRequest();
        request.setLevelType(5);  // 最大是3

        mockMvc.perform(post("/api/challenge/start")
                        .header("Authorization", bearerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    /**
     * 测试4：提交闯关结果成功（须先 start 拿到 challengeId 与每题 correctIndex）
     */
    @Test
    void submitChallenge_success() throws Exception {
        ChallengeStartRequest startReq = new ChallengeStartRequest();
        startReq.setLevelType(1);
        MvcResult startMvc = mockMvc.perform(post("/api/challenge/start")
                        .header("Authorization", bearerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(startReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andReturn();

        String startBody = startMvc.getResponse().getContentAsString(StandardCharsets.UTF_8);
        JsonNode root = objectMapper.readTree(startBody);
        JsonNode data = root.get("data");
        String challengeId = data.get("challengeId").asText();
        JsonNode questions = data.get("questions");

        List<ChallengeSubmitRequest.AnswerItem> answers = new ArrayList<>();
        for (int i = 0; i < questions.size(); i++) {
            JsonNode q = questions.get(i);
            ChallengeSubmitRequest.AnswerItem a = new ChallengeSubmitRequest.AnswerItem();
            a.setQuestionId(q.get("id").asLong());
            a.setSelectedIndex(q.get("correctIndex").asInt());
            a.setTimeSpent(1);
            answers.add(a);
        }

        ChallengeSubmitRequest request = new ChallengeSubmitRequest();
        request.setChallengeId(challengeId);
        request.setLevelType(1);
        request.setAnswers(answers);

        mockMvc.perform(post("/api/challenge/submit")
                        .header("Authorization", bearerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("success"))
                .andExpect(jsonPath("$.data.score").exists())
                .andExpect(jsonPath("$.data.correctCount").exists())
                .andExpect(jsonPath("$.data.totalCount").exists())
                .andExpect(jsonPath("$.data.accuracy").exists())
                .andExpect(jsonPath("$.data.addedScore").exists())
                .andExpect(jsonPath("$.data.totalScore").exists());
    }

    /**
     * 测试5：提交闯关结果失败 - 缺少 challengeId
     */
    @Test
    void submitChallenge_failed_missing_challengeId() throws Exception {
        List<ChallengeSubmitRequest.AnswerItem> answers = new ArrayList<>();
        ChallengeSubmitRequest.AnswerItem answer = new ChallengeSubmitRequest.AnswerItem();
        answer.setQuestionId(1L);
        answer.setSelectedIndex(0);
        answers.add(answer);

        ChallengeSubmitRequest request = new ChallengeSubmitRequest();
        request.setLevelType(1);
        request.setAnswers(answers);

        mockMvc.perform(post("/api/challenge/submit")
                        .header("Authorization", bearerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    /**
     * 测试6：提交闯关结果失败 - 缺少 answers
     */
    @Test
    void submitChallenge_failed_missing_answers() throws Exception {
        ChallengeSubmitRequest request = new ChallengeSubmitRequest();
        request.setChallengeId("ch_1701234567890");
        request.setLevelType(1);

        mockMvc.perform(post("/api/challenge/submit")
                        .header("Authorization", bearerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    /**
     * 测试7：获取闯关记录成功
     */
    @Test
    void getChallengeRecords_success() throws Exception {
        mockMvc.perform(get("/api/challenge/records")
                        .param("page", "1")
                        .param("size", "10")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("success"))
                .andExpect(jsonPath("$.data.content").isArray())
                .andExpect(jsonPath("$.data.total").exists())
                .andExpect(jsonPath("$.data.page").value(1))
                .andExpect(jsonPath("$.data.size").value(10));
    }

    /**
     * 测试8：获取闯关记录 - 按等级过滤
     */
    @Test
    void getChallengeRecords_with_level_filter() throws Exception {
        mockMvc.perform(get("/api/challenge/records")
                        .param("levelType", "1")
                        .param("page", "1")
                        .param("size", "10")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.content").exists());
    }

    /**
     * 测试9：获取闯关记录 - 默认分页参数
     */
    @Test
    void getChallengeRecords_default_pagination() throws Exception {
        mockMvc.perform(get("/api/challenge/records")
                        .header("Authorization", bearerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.page").value(1))
                .andExpect(jsonPath("$.data.size").value(20));
    }

    @Test
    void startChallenge_unauthorized() throws Exception {
        ChallengeStartRequest request = new ChallengeStartRequest();
        request.setLevelType(1);
        mockMvc.perform(post("/api/challenge/start")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));
    }
}

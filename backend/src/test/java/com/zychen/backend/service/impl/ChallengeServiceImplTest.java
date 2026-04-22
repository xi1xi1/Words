package com.zychen.backend.service.impl;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zychen.backend.common.BusinessException;
import com.zychen.backend.dto.request.ChallengeSubmitRequest;
import com.zychen.backend.dto.response.ChallengeStartResponse;
import com.zychen.backend.dto.response.ChallengeSubmitResponse;
import com.zychen.backend.entity.User;
import com.zychen.backend.entity.Word;
import com.zychen.backend.mapper.BattleRecordMapper;
import com.zychen.backend.mapper.UserMapper;
import com.zychen.backend.mapper.WordMapper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ChallengeServiceImplTest {

    @Mock
    private BattleRecordMapper battleRecordMapper;
    @Mock
    private WordMapper wordMapper;
    @Mock
    private UserMapper userMapper;
    @Mock
    private ObjectMapper objectMapper;

    @InjectMocks
    private ChallengeServiceImpl challengeService;

    @Test
    void startChallenge_levelTypeInvalid_throws400() {
        BusinessException ex = assertThrows(BusinessException.class, () -> challengeService.startChallenge(1L, 0));
        assertEquals(400, ex.getCode());
    }

    @Test
    void startChallenge_wordPoolInsufficient_throws400() {
        when(wordMapper.getRandomWords(anyInt())).thenReturn(List.of(word(1L, "a"), word(2L, "b")));
        BusinessException ex = assertThrows(BusinessException.class, () -> challengeService.startChallenge(1L, 1));
        assertEquals(400, ex.getCode());
        assertEquals("词库单词数量不足，无法开始闯关", ex.getMessage());
    }

    @Test
    void startChallenge_success_generatesQuestionsAndLimit() {
        // level 1 => 5 questions; we provide > 20 pool words
        List<Word> pool = java.util.stream.LongStream.rangeClosed(1, 25)
                .mapToObj(i -> word(i, "w" + i))
                .toList();
        when(wordMapper.getRandomWords(anyInt())).thenReturn(pool);

        ChallengeStartResponse resp = challengeService.startChallenge(1L, 1);
        assertNotNull(resp.getChallengeId());
        assertEquals(5, resp.getQuestions().size());
        assertEquals(60, resp.getTimeLimit());
        assertEquals(4, resp.getQuestions().get(0).getOptions().size());
        assertEquals(0, resp.getQuestions().get(0).getCorrectIndex());
    }

    @Test
    void submitChallenge_emptyAnswers_throws400() {
        ChallengeSubmitRequest req = new ChallengeSubmitRequest();
        req.setChallengeId("c1");
        req.setLevelType(1);
        req.setAnswers(List.of());

        BusinessException ex = assertThrows(BusinessException.class, () -> challengeService.submitChallenge(1L, req));
        assertEquals(400, ex.getCode());
        assertEquals("答案列表不能为空", ex.getMessage());
    }

    @Test
    void submitChallenge_objectMapperFails_throws500() throws Exception {
        ChallengeSubmitRequest req = new ChallengeSubmitRequest();
        req.setChallengeId("c1");
        req.setLevelType(1);
        req.setAnswers(List.of(answer(1L, 0, 1)));

        when(objectMapper.writeValueAsString(any())).thenThrow(new JsonProcessingException("boom") {});

        BusinessException ex = assertThrows(BusinessException.class, () -> challengeService.submitChallenge(1L, req));
        assertEquals(500, ex.getCode());
        assertEquals("结果序列化失败", ex.getMessage());
    }

    @Test
    void submitChallenge_userNotFoundAfterAddScore_throws404() throws Exception {
        ChallengeSubmitRequest req = new ChallengeSubmitRequest();
        req.setChallengeId("c1");
        req.setLevelType(1);
        req.setAnswers(List.of(answer(1L, 0, 1)));

        when(objectMapper.writeValueAsString(any())).thenReturn("{\"ok\":true}");
        doAnswer(inv -> {
            // simulate insert setting id
            return 1;
        }).when(battleRecordMapper).insert(any());
        when(userMapper.addScore(eq(1L), anyInt())).thenReturn(0);

        BusinessException ex = assertThrows(BusinessException.class, () -> challengeService.submitChallenge(1L, req));
        assertEquals(404, ex.getCode());
        assertEquals("用户不存在", ex.getMessage());
    }

    @Test
    void submitChallenge_success_returnsScoreAndTotalScore() throws Exception {
        ChallengeSubmitRequest req = new ChallengeSubmitRequest();
        req.setChallengeId("c1");
        req.setLevelType(1);
        // All selectedIndex==0 treated as correct
        req.setAnswers(List.of(
                answer(1L, 0, 8),
                answer(2L, 0, 12)
        ));

        when(objectMapper.writeValueAsString(any())).thenReturn("{\"ok\":true}");
        doAnswer(inv -> 1).when(battleRecordMapper).insert(any());
        when(userMapper.addScore(eq(1L), anyInt())).thenReturn(1);
        User user = new User();
        user.setId(1L);
        user.setTotalScore(1335);
        when(userMapper.findById(1L)).thenReturn(user);

        ChallengeSubmitResponse resp = challengeService.submitChallenge(1L, req);
        assertEquals(1000, resp.getScore());
        assertEquals(2, resp.getCorrectCount());
        assertEquals(2, resp.getTotalCount());
        assertEquals(1.0, resp.getAccuracy());
        assertEquals(100, resp.getAddedScore());
        assertEquals(1335, resp.getTotalScore());
    }

    private static Word word(Long id, String w) {
        Word word = new Word();
        word.setId(id);
        word.setWord(w);
        word.setMeaning("[\"m" + id + "\"]");
        return word;
    }

    private static ChallengeSubmitRequest.AnswerItem answer(Long qid, Integer selectedIndex, Integer timeSpent) {
        ChallengeSubmitRequest.AnswerItem a = new ChallengeSubmitRequest.AnswerItem();
        a.setQuestionId(qid);
        a.setSelectedIndex(selectedIndex);
        a.setTimeSpent(timeSpent);
        return a;
    }
}


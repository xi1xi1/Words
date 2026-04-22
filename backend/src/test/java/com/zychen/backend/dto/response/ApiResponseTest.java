package com.zychen.backend.dto.response;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class ApiResponseTest {

    @Test
    void success_withData_usesDefaultSuccessMessage() {
        ApiResponse<String> resp = ApiResponse.success("ok");
        assertEquals(200, resp.getCode());
        assertEquals("success", resp.getMessage());
        assertEquals("ok", resp.getData());
    }

    @Test
    void success_withCustomMessage_usesProvidedMessage() {
        ApiResponse<Integer> resp = ApiResponse.success("done", 1);
        assertEquals(200, resp.getCode());
        assertEquals("done", resp.getMessage());
        assertEquals(1, resp.getData());
    }

    @Test
    void error_withCodeAndMessage_keepsCode() {
        ApiResponse<Void> resp = ApiResponse.error(401, "unauthorized");
        assertEquals(401, resp.getCode());
        assertEquals("unauthorized", resp.getMessage());
        assertNull(resp.getData());
    }

    @Test
    void error_withMessage_usesDefault400() {
        ApiResponse<Void> resp = ApiResponse.error("bad request");
        assertEquals(400, resp.getCode());
        assertEquals("bad request", resp.getMessage());
        assertNull(resp.getData());
    }
}

package com.zychen.backend.common;

import com.zychen.backend.dto.response.ApiResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.MutablePropertyValues;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.BindException;
import org.springframework.validation.DataBinder;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    @Test
    void handleBusinessException_returnsCustomCodeAndMessage() {
        ApiResponse<Void> resp = handler.handleBusinessException(new BusinessException(403, "forbidden"));
        assertEquals(403, resp.getCode());
        assertEquals("forbidden", resp.getMessage());
        assertNull(resp.getData());
    }

    @Test
    void handleBindException_returnsBindingMessage() {
        DataBinder binder = new DataBinder(new Object(), "req");
        binder.bind(new MutablePropertyValues());
        binder.getBindingResult().addError(new FieldError("req", "page", "must be positive"));
        BindException ex = new BindException(binder.getBindingResult());

        ApiResponse<?> resp = handler.handleBindException(ex);
        assertEquals(400, resp.getCode());
        assertEquals("参数绑定失败", resp.getMessage());
    }

    @Test
    void handleHttpMessageNotReadableException_returns400() {
        ApiResponse<Void> resp = handler.handleHttpMessageNotReadableException(
                new HttpMessageNotReadableException("bad body"));
        assertEquals(400, resp.getCode());
        assertEquals("请求体格式错误", resp.getMessage());
    }

    @Test
    void handleMissingServletRequestParameter_returnsMissingField() {
        MissingServletRequestParameterException ex =
                new MissingServletRequestParameterException("size", "int");
        ApiResponse<Void> resp = handler.handleMissingServletRequestParameter(ex);
        assertEquals(400, resp.getCode());
        assertEquals("缺少参数: size", resp.getMessage());
    }

    @Test
    void handleMethodArgumentTypeMismatch_returns400() {
        MethodArgumentTypeMismatchException ex =
                new MethodArgumentTypeMismatchException("abc", Integer.class, "page", null, null);
        ApiResponse<Void> resp = handler.handleMethodArgumentTypeMismatch(ex);
        assertEquals(400, resp.getCode());
        assertEquals("参数格式错误", resp.getMessage());
    }

    @Test
    void handleException_returns500() {
        ApiResponse<Void> resp = handler.handleException(new RuntimeException("boom"));
        assertEquals(500, resp.getCode());
        assertEquals("服务器内部错误", resp.getMessage());
        assertNull(resp.getData());
    }
}

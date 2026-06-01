package com.youscout.videoservice.dto;

import java.time.ZonedDateTime;

public record ApiResponse<T>(
        boolean success,
        T data,
        String message,
        ZonedDateTime timestamp
) {
    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(true, data, "OK", ZonedDateTime.now());
    }

    public static <T> ApiResponse<T> ok(T data, String message) {
        return new ApiResponse<>(true, data, message, ZonedDateTime.now());
    }

    public static <T> ApiResponse<T> error(String message) {
        return new ApiResponse<>(false, null, message, ZonedDateTime.now());
    }
}

package com.youscout.userservice.dto;

public record AuthResponse(
        String accessToken,
        String refreshToken,
        long expiresIn,
        UserDTO user
) {}

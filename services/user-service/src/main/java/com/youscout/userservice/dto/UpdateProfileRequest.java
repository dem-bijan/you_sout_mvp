package com.youscout.userservice.dto;

public record UpdateProfileRequest(
        String displayName,
        String bio,
        String avatarUrl
) {}

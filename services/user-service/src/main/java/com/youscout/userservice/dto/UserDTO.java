package com.youscout.userservice.dto;

public record UserDTO(
        String id,
        String username,
        String displayName,
        String bio,
        String avatarUrl,
        int followerCount,
        int followingCount,
        int videoCount,
        boolean isFollowedByCurrentUser
) {}

package com.youscout.videoservice.dto;

import java.util.List;

public record VideoDTO(
        String id,
        String userId,
        String userUsername,
        String userDisplayName,
        String userAvatarUrl,
        String title,
        String description,
        String videoUrl,
        String thumbnailUrl,
        Integer durationSeconds,
        long viewsCount,
        long likesCount,
        long commentsCount,
        List<SkillDTO> skills,
        List<String> hashtags,
        boolean isLikedByCurrentUser,
        String createdAt
) {}

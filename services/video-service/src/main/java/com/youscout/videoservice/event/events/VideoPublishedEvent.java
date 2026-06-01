package com.youscout.videoservice.event.events;

public record VideoPublishedEvent(
        String videoId,
        String userId,
        String username,
        String displayName,
        String avatarUrl,
        String videoUrl,
        String thumbnailUrl,
        String description,
        long timestamp
) {}

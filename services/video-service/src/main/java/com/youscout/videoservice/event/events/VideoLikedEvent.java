package com.youscout.videoservice.event.events;

public record VideoLikedEvent(
        String videoId,
        String videoOwnerId,
        String videoThumbnail,
        String likerId,
        String likerUsername,
        long timestamp
) {}

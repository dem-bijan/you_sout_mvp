package com.youscout.videoservice.domain;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

public class VideoLikeId implements Serializable {
    private UUID videoId;
    private UUID userId;

    public VideoLikeId() {}

    public VideoLikeId(UUID videoId, UUID userId) {
        this.videoId = videoId;
        this.userId = userId;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof VideoLikeId that)) return false;
        return Objects.equals(videoId, that.videoId) && Objects.equals(userId, that.userId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(videoId, userId);
    }
}

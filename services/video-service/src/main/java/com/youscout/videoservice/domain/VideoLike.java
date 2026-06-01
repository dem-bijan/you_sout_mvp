package com.youscout.videoservice.domain;

import jakarta.persistence.*;
import java.time.ZonedDateTime;
import java.util.UUID;

@Entity
@Table(name = "video_likes")
@IdClass(VideoLikeId.class)
public class VideoLike {

    @Id
    @Column(name = "video_id")
    private UUID videoId;

    @Id
    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "created_at")
    private ZonedDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = ZonedDateTime.now();
    }

    public UUID getVideoId() { return videoId; }
    public void setVideoId(UUID videoId) { this.videoId = videoId; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public ZonedDateTime getCreatedAt() { return createdAt; }
}

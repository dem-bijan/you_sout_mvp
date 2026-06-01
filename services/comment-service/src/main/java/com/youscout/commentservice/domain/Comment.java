package com.youscout.commentservice.domain;

import jakarta.persistence.*;
import java.time.ZonedDateTime;
import java.util.UUID;

@Entity
@Table(name = "comments")
public class Comment {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "video_id", nullable = false)
    private UUID videoId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "user_username", nullable = false, length = 50)
    private String userUsername;

    @Column(name = "user_display_name", nullable = false, length = 100)
    private String userDisplayName;

    @Column(name = "user_avatar_url", length = 500)
    private String userAvatarUrl;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    @Column(name = "parent_id")
    private UUID parentId;

    @Column(name = "likes_count")
    private Integer likesCount = 0;

    @Column(name = "is_active")
    private Boolean isActive = true;

    @Column(name = "created_at")
    private ZonedDateTime createdAt;

    @PrePersist
    protected void onCreate() { createdAt = ZonedDateTime.now(); }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getVideoId() { return videoId; }
    public void setVideoId(UUID videoId) { this.videoId = videoId; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public String getUserUsername() { return userUsername; }
    public void setUserUsername(String userUsername) { this.userUsername = userUsername; }
    public String getUserDisplayName() { return userDisplayName; }
    public void setUserDisplayName(String userDisplayName) { this.userDisplayName = userDisplayName; }
    public String getUserAvatarUrl() { return userAvatarUrl; }
    public void setUserAvatarUrl(String userAvatarUrl) { this.userAvatarUrl = userAvatarUrl; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public UUID getParentId() { return parentId; }
    public void setParentId(UUID parentId) { this.parentId = parentId; }
    public Integer getLikesCount() { return likesCount; }
    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }
    public ZonedDateTime getCreatedAt() { return createdAt; }
}

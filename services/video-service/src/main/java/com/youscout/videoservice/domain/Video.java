package com.youscout.videoservice.domain;

import jakarta.persistence.*;
import java.time.ZonedDateTime;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

@Entity
@Table(name = "videos")
public class Video {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "user_username", nullable = false, length = 50)
    private String userUsername;

    @Column(name = "user_display_name", nullable = false, length = 100)
    private String userDisplayName;

    @Column(name = "user_avatar_url", length = 500)
    private String userAvatarUrl;

    @Column(length = 255)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "minio_key", nullable = false, length = 500)
    private String minioKey;

    @Column(name = "video_url", nullable = false, length = 1000)
    private String videoUrl;

    @Column(name = "thumbnail_url", length = 1000)
    private String thumbnailUrl;

    @Column(name = "duration_seconds")
    private Integer durationSeconds;

    @Column(name = "views_count")
    private Long viewsCount = 0L;

    @Column(name = "likes_count")
    private Long likesCount = 0L;

    @Column(name = "comments_count")
    private Long commentsCount = 0L;

    @Column(name = "is_active")
    private Boolean isActive = true;

    @Column(name = "created_at")
    private ZonedDateTime createdAt;

    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(name = "video_skills",
            joinColumns = @JoinColumn(name = "video_id"),
            inverseJoinColumns = @JoinColumn(name = "skill_id"))
    private Set<Skill> skills = new HashSet<>();

    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(name = "video_hashtags",
            joinColumns = @JoinColumn(name = "video_id"),
            inverseJoinColumns = @JoinColumn(name = "hashtag_id"))
    private Set<Hashtag> hashtags = new HashSet<>();

    @PrePersist
    protected void onCreate() {
        createdAt = ZonedDateTime.now();
    }

    // Getters and setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public String getUserUsername() { return userUsername; }
    public void setUserUsername(String userUsername) { this.userUsername = userUsername; }
    public String getUserDisplayName() { return userDisplayName; }
    public void setUserDisplayName(String userDisplayName) { this.userDisplayName = userDisplayName; }
    public String getUserAvatarUrl() { return userAvatarUrl; }
    public void setUserAvatarUrl(String userAvatarUrl) { this.userAvatarUrl = userAvatarUrl; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getMinioKey() { return minioKey; }
    public void setMinioKey(String minioKey) { this.minioKey = minioKey; }
    public String getVideoUrl() { return videoUrl; }
    public void setVideoUrl(String videoUrl) { this.videoUrl = videoUrl; }
    public String getThumbnailUrl() { return thumbnailUrl; }
    public void setThumbnailUrl(String thumbnailUrl) { this.thumbnailUrl = thumbnailUrl; }
    public Integer getDurationSeconds() { return durationSeconds; }
    public void setDurationSeconds(Integer durationSeconds) { this.durationSeconds = durationSeconds; }
    public Long getViewsCount() { return viewsCount; }
    public void setViewsCount(Long viewsCount) { this.viewsCount = viewsCount; }
    public Long getLikesCount() { return likesCount; }
    public void setLikesCount(Long likesCount) { this.likesCount = likesCount; }
    public Long getCommentsCount() { return commentsCount; }
    public void setCommentsCount(Long commentsCount) { this.commentsCount = commentsCount; }
    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }
    public ZonedDateTime getCreatedAt() { return createdAt; }
    public Set<Skill> getSkills() { return skills; }
    public void setSkills(Set<Skill> skills) { this.skills = skills; }
    public Set<Hashtag> getHashtags() { return hashtags; }
    public void setHashtags(Set<Hashtag> hashtags) { this.hashtags = hashtags; }
}

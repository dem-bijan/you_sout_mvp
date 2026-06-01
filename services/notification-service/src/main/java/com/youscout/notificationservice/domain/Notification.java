package com.youscout.notificationservice.domain;

import jakarta.persistence.*;
import java.time.ZonedDateTime;
import java.util.UUID;

@Entity
@Table(name = "notifications")
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "recipient_id", nullable = false)
    private UUID recipientId;

    @Column(nullable = false, length = 50)
    private String type; // NEW_FOLLOWER, VIDEO_LIKED, NEW_COMMENT

    @Column(name = "actor_id", nullable = false)
    private UUID actorId;

    @Column(name = "actor_username", nullable = false, length = 50)
    private String actorUsername;

    @Column(name = "actor_avatar_url", length = 500)
    private String actorAvatarUrl;

    @Column(name = "reference_id")
    private UUID referenceId;

    @Column(name = "reference_preview", length = 200)
    private String referencePreview;

    @Column(name = "is_read")
    private Boolean isRead = false;

    @Column(name = "created_at")
    private ZonedDateTime createdAt;

    @PrePersist
    protected void onCreate() { createdAt = ZonedDateTime.now(); }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getRecipientId() { return recipientId; }
    public void setRecipientId(UUID recipientId) { this.recipientId = recipientId; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public UUID getActorId() { return actorId; }
    public void setActorId(UUID actorId) { this.actorId = actorId; }
    public String getActorUsername() { return actorUsername; }
    public void setActorUsername(String actorUsername) { this.actorUsername = actorUsername; }
    public String getActorAvatarUrl() { return actorAvatarUrl; }
    public void setActorAvatarUrl(String actorAvatarUrl) { this.actorAvatarUrl = actorAvatarUrl; }
    public UUID getReferenceId() { return referenceId; }
    public void setReferenceId(UUID referenceId) { this.referenceId = referenceId; }
    public String getReferencePreview() { return referencePreview; }
    public void setReferencePreview(String referencePreview) { this.referencePreview = referencePreview; }
    public Boolean getIsRead() { return isRead; }
    public void setIsRead(Boolean isRead) { this.isRead = isRead; }
    public ZonedDateTime getCreatedAt() { return createdAt; }
}

package com.youscout.socialservice.domain;

import jakarta.persistence.*;
import java.io.Serializable;
import java.time.ZonedDateTime;
import java.util.Objects;
import java.util.UUID;

@Entity
@Table(name = "follows")
@IdClass(Follow.FollowId.class)
public class Follow {

    @Id
    @Column(name = "follower_id")
    private UUID followerId;

    @Id
    @Column(name = "following_id")
    private UUID followingId;

    @Column(name = "created_at")
    private ZonedDateTime createdAt;

    @PrePersist
    protected void onCreate() { createdAt = ZonedDateTime.now(); }

    public UUID getFollowerId() { return followerId; }
    public void setFollowerId(UUID followerId) { this.followerId = followerId; }
    public UUID getFollowingId() { return followingId; }
    public void setFollowingId(UUID followingId) { this.followingId = followingId; }
    public ZonedDateTime getCreatedAt() { return createdAt; }

    public static class FollowId implements Serializable {
        private UUID followerId;
        private UUID followingId;
        public FollowId() {}
        public FollowId(UUID followerId, UUID followingId) { this.followerId = followerId; this.followingId = followingId; }
        @Override public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof FollowId that)) return false;
            return Objects.equals(followerId, that.followerId) && Objects.equals(followingId, that.followingId);
        }
        @Override public int hashCode() { return Objects.hash(followerId, followingId); }
    }
}

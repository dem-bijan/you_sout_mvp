package com.youscout.feedservice.event;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

@Component
public class FeedKafkaConsumer {

    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;
    private final RestTemplate restTemplate;

    private static final int MAX_FEED_SIZE = 500;
    private static final long FEED_TTL_DAYS = 7;

    public FeedKafkaConsumer(StringRedisTemplate redisTemplate, ObjectMapper objectMapper) {
        this.redisTemplate = redisTemplate;
        this.objectMapper = objectMapper;
        this.restTemplate = new RestTemplate();
    }

    @KafkaListener(topics = "youscout.video.published", groupId = "feed-service")
    public void onVideoPublished(String message) {
        try {
            Map<String, Object> event = objectMapper.readValue(message, Map.class);
            String videoId = (String) event.get("videoId");
            String userId = (String) event.get("userId");
            long timestamp = event.get("timestamp") instanceof Number n ? n.longValue() : System.currentTimeMillis();

            // Cache video metadata
            String metaKey = "video:meta:" + videoId;
            redisTemplate.opsForHash().putAll(metaKey, Map.of(
                    "videoId", videoId,
                    "userId", userId,
                    "username", String.valueOf(event.getOrDefault("username", "")),
                    "displayName", String.valueOf(event.getOrDefault("displayName", "")),
                    "avatarUrl", String.valueOf(event.getOrDefault("avatarUrl", "")),
                    "videoUrl", String.valueOf(event.getOrDefault("videoUrl", "")),
                    "description", String.valueOf(event.getOrDefault("description", "")),
                    "timestamp", String.valueOf(timestamp)
            ));
            redisTemplate.expire(metaKey, FEED_TTL_DAYS, TimeUnit.DAYS);

            // Fan-out: add video to each follower's feed
            // In production, we'd call social-service to get follower list
            // For MVP, we also add to the explore feed
            String exploreFeedKey = "feed:explore";
            redisTemplate.opsForZSet().add(exploreFeedKey, videoId, timestamp);

            // Trim explore feed to max size
            long size = redisTemplate.opsForZSet().zCard(exploreFeedKey);
            if (size > MAX_FEED_SIZE) {
                redisTemplate.opsForZSet().removeRange(exploreFeedKey, 0, size - MAX_FEED_SIZE - 1);
            }

            // Also add to author's own feed
            String authorFeedKey = "feed:" + userId;
            redisTemplate.opsForZSet().add(authorFeedKey, videoId, timestamp);
            redisTemplate.expire(authorFeedKey, FEED_TTL_DAYS, TimeUnit.DAYS);

        } catch (Exception e) {
            // Log error - in production, send to DLT
            System.err.println("Error processing video published event: " + e.getMessage());
        }
    }

    @KafkaListener(topics = "youscout.user.followed", groupId = "feed-service")
    public void onUserFollowed(String message) {
        try {
            Map<String, Object> event = objectMapper.readValue(message, Map.class);
            String followerId = (String) event.get("followerId");
            String followingId = (String) event.get("followingId");

            // Backfill: add the new following's recent videos to the follower's feed
            // Get recent videos from video-service or from Redis cache
            String followerFeedKey = "feed:" + followerId;

            // For now, copy from the followed user's feed
            String followingFeedKey = "feed:" + followingId;
            var recentVideos = redisTemplate.opsForZSet().reverseRangeWithScores(followingFeedKey, 0, 19);
            if (recentVideos != null) {
                recentVideos.forEach(tuple -> {
                    redisTemplate.opsForZSet().add(followerFeedKey, tuple.getValue(), tuple.getScore());
                });
            }
            redisTemplate.expire(followerFeedKey, FEED_TTL_DAYS, TimeUnit.DAYS);

        } catch (Exception e) {
            System.err.println("Error processing user followed event: " + e.getMessage());
        }
    }
}

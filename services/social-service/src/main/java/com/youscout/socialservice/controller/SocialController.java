package com.youscout.socialservice.controller;

import com.youscout.socialservice.domain.Follow;
import com.youscout.socialservice.repository.FollowRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.time.ZonedDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/social")
public class SocialController {

    private final FollowRepository followRepository;
    private final KafkaTemplate<String, Object> kafkaTemplate;
    private final RestTemplate restTemplate;

    @Value("${user-service.url:http://user-service:8081}")
    private String userServiceUrl;

    public SocialController(FollowRepository followRepository,
                            KafkaTemplate<String, Object> kafkaTemplate) {
        this.followRepository = followRepository;
        this.kafkaTemplate = kafkaTemplate;
        this.restTemplate = new RestTemplate();
    }

    @PostMapping("/follow/{targetUserId}")
    @Transactional
    public ResponseEntity<Map<String, Object>> follow(
            @PathVariable UUID targetUserId,
            @RequestHeader("X-User-Id") String userId) {

        UUID followerId = UUID.fromString(userId);
        if (followerId.equals(targetUserId)) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", "Cannot follow yourself"));
        }
        if (followRepository.existsByFollowerIdAndFollowingId(followerId, targetUserId)) {
            return ResponseEntity.ok(Map.of("success", true, "data", Map.of("isFollowing", true), "message", "Already following"));
        }

        Follow follow = new Follow();
        follow.setFollowerId(followerId);
        follow.setFollowingId(targetUserId);
        followRepository.save(follow);

        // Update counts on user-service
        try {
            restTemplate.put(userServiceUrl + "/users/" + targetUserId + "/follower-count?delta=1", null);
            restTemplate.put(userServiceUrl + "/users/" + followerId + "/following-count?delta=1", null);
        } catch (Exception e) {
            // Log but don't fail — eventual consistency
        }

        // Publish Kafka event
        kafkaTemplate.send("youscout.user.followed", targetUserId.toString(), Map.of(
                "followerId", followerId.toString(),
                "followingId", targetUserId.toString(),
                "followerUsername", "user",
                "timestamp", System.currentTimeMillis()
        ));

        return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("isFollowing", true),
                "message", "Followed",
                "timestamp", ZonedDateTime.now().toString()
        ));
    }

    @DeleteMapping("/follow/{targetUserId}")
    @Transactional
    public ResponseEntity<Map<String, Object>> unfollow(
            @PathVariable UUID targetUserId,
            @RequestHeader("X-User-Id") String userId) {

        UUID followerId = UUID.fromString(userId);
        Follow.FollowId id = new Follow.FollowId(followerId, targetUserId);

        if (!followRepository.existsById(id)) {
            return ResponseEntity.ok(Map.of("success", true, "data", Map.of("isFollowing", false), "message", "Not following"));
        }

        followRepository.deleteById(id);

        try {
            restTemplate.put(userServiceUrl + "/users/" + targetUserId + "/follower-count?delta=-1", null);
            restTemplate.put(userServiceUrl + "/users/" + followerId + "/following-count?delta=-1", null);
        } catch (Exception e) {
            // Log but don't fail
        }

        return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("isFollowing", false),
                "message", "Unfollowed",
                "timestamp", ZonedDateTime.now().toString()
        ));
    }

    @GetMapping("/is-following/{targetId}")
    public ResponseEntity<Map<String, Object>> isFollowing(
            @PathVariable UUID targetId,
            @RequestHeader("X-User-Id") String userId) {
        boolean following = followRepository.existsByFollowerIdAndFollowingId(UUID.fromString(userId), targetId);
        return ResponseEntity.ok(Map.of("success", true, "data", Map.of("isFollowing", following)));
    }

    @GetMapping("/{userId}/followers")
    public ResponseEntity<Map<String, Object>> getFollowers(
            @PathVariable UUID userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Page<Follow> followers = followRepository.findByFollowingId(userId, PageRequest.of(page, size));
        List<String> ids = followers.getContent().stream()
                .map(f -> f.getFollowerId().toString()).toList();
        return ResponseEntity.ok(Map.of("success", true, "data", ids));
    }

    @GetMapping("/{userId}/following")
    public ResponseEntity<Map<String, Object>> getFollowing(
            @PathVariable UUID userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Page<Follow> following = followRepository.findByFollowerId(userId, PageRequest.of(page, size));
        List<String> ids = following.getContent().stream()
                .map(f -> f.getFollowingId().toString()).toList();
        return ResponseEntity.ok(Map.of("success", true, "data", ids));
    }

    @GetMapping("/followers/{userId}")
    public ResponseEntity<List<String>> getFollowerIds(@PathVariable UUID userId) {
        List<String> ids = followRepository.findFollowerIdsByFollowingId(userId).stream()
                .map(UUID::toString).toList();
        return ResponseEntity.ok(ids);
    }
}

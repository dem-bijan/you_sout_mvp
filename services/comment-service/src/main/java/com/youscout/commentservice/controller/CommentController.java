package com.youscout.commentservice.controller;

import com.youscout.commentservice.domain.Comment;
import com.youscout.commentservice.repository.CommentRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.web.bind.annotation.*;

import java.time.ZonedDateTime;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/comments")
public class CommentController {

    private final CommentRepository commentRepository;
    private final KafkaTemplate<String, Object> kafkaTemplate;

    public CommentController(CommentRepository commentRepository, KafkaTemplate<String, Object> kafkaTemplate) {
        this.commentRepository = commentRepository;
        this.kafkaTemplate = kafkaTemplate;
    }

    @PostMapping
    public ResponseEntity<Map<String, Object>> createComment(
            @RequestBody Map<String, String> body,
            @RequestHeader("X-User-Id") String userId) {

        Comment comment = new Comment();
        comment.setVideoId(UUID.fromString(body.get("videoId")));
        comment.setUserId(UUID.fromString(userId));
        comment.setUserUsername(body.getOrDefault("username", "user"));
        comment.setUserDisplayName(body.getOrDefault("displayName", "User"));
        comment.setUserAvatarUrl(body.get("avatarUrl"));
        comment.setContent(body.get("content"));
        if (body.containsKey("parentId") && body.get("parentId") != null) {
            comment.setParentId(UUID.fromString(body.get("parentId")));
        }

        comment = commentRepository.save(comment);

        // Publish Kafka event
        String preview = comment.getContent().length() > 100
                ? comment.getContent().substring(0, 100) : comment.getContent();
        kafkaTemplate.send("youscout.comment.created", comment.getVideoId().toString(), Map.of(
                "commentId", comment.getId().toString(),
                "videoId", comment.getVideoId().toString(),
                "videoOwnerId", body.getOrDefault("videoOwnerId", ""),
                "commenterId", userId,
                "commenterUsername", comment.getUserUsername(),
                "commentPreview", preview,
                "timestamp", System.currentTimeMillis()
        ));

        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "success", true,
                "data", Map.of(
                        "id", comment.getId().toString(),
                        "videoId", comment.getVideoId().toString(),
                        "content", comment.getContent(),
                        "userUsername", comment.getUserUsername(),
                        "userDisplayName", comment.getUserDisplayName(),
                        "createdAt", comment.getCreatedAt().toString()
                ),
                "message", "Comment created",
                "timestamp", ZonedDateTime.now().toString()
        ));
    }

    @GetMapping("/video/{videoId}")
    public ResponseEntity<Map<String, Object>> getComments(
            @PathVariable UUID videoId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Page<Comment> comments = commentRepository.findByVideoIdAndIsActiveTrueOrderByCreatedAtDesc(
                videoId, PageRequest.of(page, size));

        var data = comments.map(c -> Map.of(
                "id", c.getId().toString(),
                "videoId", c.getVideoId().toString(),
                "userId", c.getUserId().toString(),
                "userUsername", c.getUserUsername(),
                "userDisplayName", c.getUserDisplayName(),
                "userAvatarUrl", c.getUserAvatarUrl() != null ? c.getUserAvatarUrl() : "",
                "content", c.getContent(),
                "parentId", c.getParentId() != null ? c.getParentId().toString() : "",
                "likesCount", c.getLikesCount(),
                "createdAt", c.getCreatedAt().toString()
        ));

        return ResponseEntity.ok(Map.of(
                "success", true,
                "data", data,
                "message", "OK",
                "timestamp", ZonedDateTime.now().toString()
        ));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteComment(
            @PathVariable UUID id,
            @RequestHeader("X-User-Id") String userId) {
        Comment comment = commentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Comment not found"));
        if (!comment.getUserId().equals(UUID.fromString(userId))) {
            throw new RuntimeException("Not authorized");
        }
        comment.setIsActive(false);
        commentRepository.save(comment);
        return ResponseEntity.noContent().build();
    }
}

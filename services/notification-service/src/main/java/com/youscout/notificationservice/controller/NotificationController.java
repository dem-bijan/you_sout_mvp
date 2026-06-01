package com.youscout.notificationservice.controller;

import com.youscout.notificationservice.domain.Notification;
import com.youscout.notificationservice.repository.NotificationRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.ZonedDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/notifications")
public class NotificationController {

    private final NotificationRepository notificationRepository;

    public NotificationController(NotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    @GetMapping
    public ResponseEntity<Map<String, Object>> getNotifications(
            @RequestHeader("X-User-Id") String userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Page<Notification> notifications = notificationRepository.findByRecipientIdOrderByCreatedAtDesc(
                UUID.fromString(userId), PageRequest.of(page, size));

        var data = notifications.map(n -> Map.of(
                "id", n.getId().toString(),
                "type", n.getType(),
                "actorId", n.getActorId().toString(),
                "actorUsername", n.getActorUsername(),
                "actorAvatarUrl", n.getActorAvatarUrl() != null ? n.getActorAvatarUrl() : "",
                "referenceId", n.getReferenceId() != null ? n.getReferenceId().toString() : "",
                "referencePreview", n.getReferencePreview() != null ? n.getReferencePreview() : "",
                "isRead", n.getIsRead(),
                "createdAt", n.getCreatedAt().toString()
        ));

        return ResponseEntity.ok(Map.of(
                "success", true,
                "data", data,
                "message", "OK",
                "timestamp", ZonedDateTime.now().toString()
        ));
    }

    @PostMapping("/mark-read")
    @Transactional
    public ResponseEntity<Map<String, Object>> markAsRead(
            @RequestHeader("X-User-Id") String userId,
            @RequestBody Map<String, List<String>> body) {
        List<UUID> ids = body.get("ids").stream().map(UUID::fromString).toList();
        notificationRepository.markAsRead(ids, UUID.fromString(userId));
        return ResponseEntity.ok(Map.of("success", true, "message", "Marked as read"));
    }

    @PostMapping("/mark-all-read")
    @Transactional
    public ResponseEntity<Map<String, Object>> markAllAsRead(@RequestHeader("X-User-Id") String userId) {
        notificationRepository.markAllAsRead(UUID.fromString(userId));
        return ResponseEntity.ok(Map.of("success", true, "message", "All marked as read"));
    }

    @GetMapping("/unread-count")
    public ResponseEntity<Map<String, Object>> getUnreadCount(@RequestHeader("X-User-Id") String userId) {
        long count = notificationRepository.countByRecipientIdAndIsReadFalse(UUID.fromString(userId));
        return ResponseEntity.ok(Map.of("success", true, "data", Map.of("count", count)));
    }
}

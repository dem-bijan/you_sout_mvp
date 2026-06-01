package com.youscout.notificationservice.event;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.youscout.notificationservice.domain.Notification;
import com.youscout.notificationservice.repository.NotificationRepository;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.UUID;

@Component
public class NotificationKafkaConsumer {

    private final NotificationRepository notificationRepository;
    private final ObjectMapper objectMapper;

    public NotificationKafkaConsumer(NotificationRepository notificationRepository, ObjectMapper objectMapper) {
        this.notificationRepository = notificationRepository;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "youscout.user.followed", groupId = "notification-service")
    public void onUserFollowed(String message) {
        try {
            Map<String, Object> event = objectMapper.readValue(message, Map.class);
            createNotification(
                    (String) event.get("followingId"),
                    "NEW_FOLLOWER",
                    (String) event.get("followerId"),
                    (String) event.getOrDefault("followerUsername", "user"),
                    null, null
            );
        } catch (Exception e) {
            System.err.println("Error processing user.followed: " + e.getMessage());
        }
    }

    @KafkaListener(topics = "youscout.video.liked", groupId = "notification-service")
    public void onVideoLiked(String message) {
        try {
            Map<String, Object> event = objectMapper.readValue(message, Map.class);
            createNotification(
                    (String) event.get("videoOwnerId"),
                    "VIDEO_LIKED",
                    (String) event.get("likerId"),
                    (String) event.getOrDefault("likerUsername", "user"),
                    (String) event.get("videoId"),
                    (String) event.get("videoThumbnail")
            );
        } catch (Exception e) {
            System.err.println("Error processing video.liked: " + e.getMessage());
        }
    }

    @KafkaListener(topics = "youscout.comment.created", groupId = "notification-service")
    public void onCommentCreated(String message) {
        try {
            Map<String, Object> event = objectMapper.readValue(message, Map.class);
            createNotification(
                    (String) event.get("videoOwnerId"),
                    "NEW_COMMENT",
                    (String) event.get("commenterId"),
                    (String) event.getOrDefault("commenterUsername", "user"),
                    (String) event.get("videoId"),
                    (String) event.get("commentPreview")
            );
        } catch (Exception e) {
            System.err.println("Error processing comment.created: " + e.getMessage());
        }
    }

    private void createNotification(String recipientId, String type, String actorId,
                                     String actorUsername, String referenceId, String referencePreview) {
        if (recipientId == null || recipientId.isEmpty()) return;
        // Don't notify yourself
        if (recipientId.equals(actorId)) return;

        Notification notification = new Notification();
        notification.setRecipientId(UUID.fromString(recipientId));
        notification.setType(type);
        notification.setActorId(UUID.fromString(actorId));
        notification.setActorUsername(actorUsername);
        if (referenceId != null && !referenceId.isEmpty()) {
            notification.setReferenceId(UUID.fromString(referenceId));
        }
        notification.setReferencePreview(referencePreview);
        notificationRepository.save(notification);
    }
}

package com.youscout.notificationservice.repository;

import com.youscout.notificationservice.domain.Notification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, UUID> {
    Page<Notification> findByRecipientIdOrderByCreatedAtDesc(UUID recipientId, Pageable pageable);
    long countByRecipientIdAndIsReadFalse(UUID recipientId);

    @Modifying
    @Query("UPDATE Notification n SET n.isRead = true WHERE n.id IN :ids AND n.recipientId = :recipientId")
    void markAsRead(List<UUID> ids, UUID recipientId);

    @Modifying
    @Query("UPDATE Notification n SET n.isRead = true WHERE n.recipientId = :recipientId")
    void markAllAsRead(UUID recipientId);
}

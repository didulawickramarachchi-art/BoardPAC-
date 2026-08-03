package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.NotificationReaction;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface NotificationReactionRepository extends JpaRepository<NotificationReaction, Long> {
    List<NotificationReaction> findByNotificationId(Long notificationId);
    Optional<NotificationReaction> findByNotificationIdAndUserId(Long notificationId, Long userId);
}

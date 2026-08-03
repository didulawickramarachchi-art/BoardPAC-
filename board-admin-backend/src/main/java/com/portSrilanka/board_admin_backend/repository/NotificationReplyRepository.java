package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.NotificationReply;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface NotificationReplyRepository extends JpaRepository<NotificationReply, Long> {
    List<NotificationReply> findByNotificationIdOrderByCreatedAtAsc(Long notificationId);
}

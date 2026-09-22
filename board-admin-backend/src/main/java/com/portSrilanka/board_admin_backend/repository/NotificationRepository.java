package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.BoardNotification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface NotificationRepository extends JpaRepository<BoardNotification, Long> {
    List<BoardNotification> findByRecipientIdOrderByCreatedAtDesc(Long recipientId);
    List<BoardNotification> findByRecipientIdOrderByCreatedAtDesc(Long recipientId, Pageable pageable);
}

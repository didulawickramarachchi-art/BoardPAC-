package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.AttachmentReaction;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface AttachmentReactionRepository extends JpaRepository<AttachmentReaction, Long> {
    List<AttachmentReaction> findByAttachmentId(Long attachmentId);
    Optional<AttachmentReaction> findByAttachmentIdAndUserId(Long attachmentId, Long userId);
}

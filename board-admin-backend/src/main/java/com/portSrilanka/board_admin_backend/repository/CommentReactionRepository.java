package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.CommentReaction;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.List;

public interface CommentReactionRepository extends JpaRepository<CommentReaction, Long> {
    long countByCommentId(Long commentId);
    Optional<CommentReaction> findByCommentIdAndUserId(Long commentId, Long userId);
    List<CommentReaction> findByCommentId(Long commentId);
}

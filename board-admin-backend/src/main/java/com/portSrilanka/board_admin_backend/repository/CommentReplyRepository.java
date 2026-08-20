package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.CommentReply;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CommentReplyRepository extends JpaRepository<CommentReply, Long> {
    List<CommentReply> findByCommentIdOrderByCreatedAtAsc(Long commentId);
}

package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.CommentShare;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CommentShareRepository extends JpaRepository<CommentShare, Long> {
    List<CommentShare> findBySharedToId(Long userId);
}

package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.PaperShare;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PaperShareRepository extends JpaRepository<PaperShare, Long> {
    List<PaperShare> findBySharedToId(Long userId);
}

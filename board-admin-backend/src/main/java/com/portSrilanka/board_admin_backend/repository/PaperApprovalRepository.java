package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.PaperApproval;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PaperApprovalRepository extends JpaRepository<PaperApproval, Long> {
    List<PaperApproval> findByPaperId(Long paperId);
    Optional<PaperApproval> findByPaperIdAndUserId(Long paperId, Long userId);
}

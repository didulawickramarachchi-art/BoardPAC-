package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.PaperAttachment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PaperAttachmentRepository extends JpaRepository<PaperAttachment, Long> {
    List<PaperAttachment> findByPaperIdOrderByDisplayOrderAsc(Long paperId);
}
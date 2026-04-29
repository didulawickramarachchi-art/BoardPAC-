package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.AnnotationBackup;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AnnotationBackupRepository extends JpaRepository<AnnotationBackup, Long> {
    List<AnnotationBackup> findByUserIdOrderByCreatedAtDesc(Long userId);
}

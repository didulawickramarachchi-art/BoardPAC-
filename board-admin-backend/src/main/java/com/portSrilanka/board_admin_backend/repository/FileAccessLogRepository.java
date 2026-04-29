package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.FileAccessLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FileAccessLogRepository extends JpaRepository<FileAccessLog, Long> {
    List<FileAccessLog> findByUserId(Long userId);
    List<FileAccessLog> findByPaperId(Long paperId);
}

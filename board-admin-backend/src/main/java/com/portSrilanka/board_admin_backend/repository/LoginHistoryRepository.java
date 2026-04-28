package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.LoginHistory;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LoginHistoryRepository extends JpaRepository<LoginHistory, Long> {
}
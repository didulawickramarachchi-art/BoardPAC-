package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.UserSession;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserSessionRepository extends JpaRepository<UserSession, Long> {
    Optional<UserSession> findBySessionTokenAndActiveTrue(String sessionToken);
    List<UserSession> findByUserIdAndActiveTrue(Long userId);
}

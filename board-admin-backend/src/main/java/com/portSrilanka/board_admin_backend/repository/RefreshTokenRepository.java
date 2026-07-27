package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.List;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {
    Optional<RefreshToken> findByTokenAndRevokedFalse(String token);
    List<RefreshToken> findByUserIdAndRevokedFalse(Long userId);
}

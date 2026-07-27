package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.PasswordResetToken;
import com.portSrilanka.board_admin_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PasswordResetTokenRepository extends JpaRepository<PasswordResetToken, Long> {
    Optional<PasswordResetToken> findByTokenHash(String tokenHash);
    void deleteByUser(User user);
}

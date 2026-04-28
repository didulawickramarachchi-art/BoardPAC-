package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.TwoFactorCode;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface TwoFactorCodeRepository extends JpaRepository<TwoFactorCode, Long> {
    Optional<TwoFactorCode> findTopByUserIdAndCodeAndUsedFalseOrderByCreatedAtDesc(Long userId, String code);
}
package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.UserSubcategoryAccess;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserSubcategoryAccessRepository extends JpaRepository<UserSubcategoryAccess, Long> {
    List<UserSubcategoryAccess> findByUserId(Long userId);
    List<UserSubcategoryAccess> findBySubcategoryId(Long subcategoryId);
    Optional<UserSubcategoryAccess> findByUserIdAndSubcategoryId(Long userId, Long subcategoryId);
    void deleteByUserIdAndSubcategoryId(Long userId, Long subcategoryId);
}

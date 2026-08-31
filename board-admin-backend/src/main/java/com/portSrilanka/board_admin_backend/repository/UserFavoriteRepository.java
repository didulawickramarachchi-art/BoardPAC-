package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.UserFavorite;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;

public interface UserFavoriteRepository extends JpaRepository<UserFavorite, Long> {
    List<UserFavorite> findByUserIdOrderByCreatedAtDesc(Long userId);
    Optional<UserFavorite> findByUserIdAndFavoriteTypeAndTargetId(
            Long userId, String favoriteType, Long targetId);
}

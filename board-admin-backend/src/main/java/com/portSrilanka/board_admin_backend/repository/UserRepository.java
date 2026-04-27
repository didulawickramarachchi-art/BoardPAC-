package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);
    boolean existsByUsername(String username);
    boolean existsByBoardEmail(String boardEmail);
}
package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.Role;
import com.portSrilanka.board_admin_backend.enums.SystemRole;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface RoleRepository extends JpaRepository<Role, Long> {
    Optional<Role> findByName(SystemRole name);
}
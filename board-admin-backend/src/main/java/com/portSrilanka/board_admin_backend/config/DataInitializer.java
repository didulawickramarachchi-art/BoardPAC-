package com.portSrilanka.board_admin_backend.config;

import com.portSrilanka.board_admin_backend.entity.Role;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.enums.BoardType;
import com.portSrilanka.board_admin_backend.enums.SystemRole;
import com.portSrilanka.board_admin_backend.enums.UserStatus;
import com.portSrilanka.board_admin_backend.repository.RoleRepository;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.util.Set;

@Component
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    private static final String DEFAULT_ADMIN_USERNAME = "admin";
    private static final String DEFAULT_ADMIN_PASSWORD = "123456";

    private final RoleRepository roleRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        Role adminRole = roleRepository.findByName(SystemRole.ADMIN)
                .orElseGet(() -> roleRepository.save(Role.builder()
                        .name(SystemRole.ADMIN)
                        .build()));

        roleRepository.findByName(SystemRole.SECRETARY)
                .orElseGet(() -> roleRepository.save(Role.builder()
                        .name(SystemRole.SECRETARY)
                        .build()));

        roleRepository.findByName(SystemRole.MEMBER)
                .orElseGet(() -> roleRepository.save(Role.builder()
                        .name(SystemRole.MEMBER)
                        .build()));

        if (userRepository.existsByUsername(DEFAULT_ADMIN_USERNAME)) {
            return;
        }

        User admin = User.builder()
                .username(DEFAULT_ADMIN_USERNAME)
                .password(passwordEncoder.encode(DEFAULT_ADMIN_PASSWORD))
                .firstName("System")
                .lastName("Administrator")
                .displayName("System Administrator")
                .boardEmail("admin@boardsrilanka.local")
                .boardType(BoardType.ORGANIZER)
                .status(UserStatus.ACTIVE)
                .roles(Set.of(adminRole))
                .build();

        userRepository.save(admin);
    }
}

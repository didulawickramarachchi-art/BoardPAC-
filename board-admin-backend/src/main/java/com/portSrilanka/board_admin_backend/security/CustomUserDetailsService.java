package com.portSrilanka.board_admin_backend.security;

import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.*;
import org.springframework.stereotype.Service;

import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        return new org.springframework.security.core.userdetails.User(
                user.getUsername(),
                user.getPassword(),
                user.getStatus().name().equals("ACTIVE"),
                true,
                true,
                !user.getStatus().name().equals("LOCKED"),
                user.getRoles().stream()
                        .map(role -> new SimpleGrantedAuthority(
                                "ROLE_" + role.getName().authorityName()))
                        .collect(Collectors.toSet())
        );
    }
}

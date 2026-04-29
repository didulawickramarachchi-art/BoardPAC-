package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.entity.UserSession;
import com.portSrilanka.board_admin_backend.enums.AccessChannel;
import com.portSrilanka.board_admin_backend.repository.UserSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SessionService {

    private final UserSessionRepository userSessionRepository;

    public String createSession(User user, AccessChannel accessChannel, String deviceInfo, String ipAddress) {
        UserSession session = UserSession.builder()
                .user(user)
                .sessionToken(UUID.randomUUID().toString())
                .accessChannel(accessChannel)
                .deviceInfo(deviceInfo)
                .ipAddress(ipAddress)
                .expiresAt(LocalDateTime.now().plusDays(7))
                .active(true)
                .build();

        return userSessionRepository.save(session).getSessionToken();
    }

    public void revokeAllUserSessions(Long userId) {
        userSessionRepository.findByUserIdAndActiveTrue(userId).forEach(session -> {
            session.setActive(false);
            userSessionRepository.save(session);
        });
    }
}

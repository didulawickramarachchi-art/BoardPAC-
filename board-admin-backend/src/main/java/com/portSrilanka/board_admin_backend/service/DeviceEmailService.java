package com.portSrilanka.board_admin_backend.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

/** Sends device notices after the login or approval HTTP response can proceed. */
@Service
@RequiredArgsConstructor
@Slf4j
public class DeviceEmailService {
    private final EmailService emailService;

    @Async
    public void send(String address, String subject, String body) {
        if (address == null || address.isBlank()) return;
        try {
            emailService.sendEmail(address, subject, body);
        } catch (RuntimeException exception) {
            log.warn("Unable to send device notification email", exception);
        }
    }
}

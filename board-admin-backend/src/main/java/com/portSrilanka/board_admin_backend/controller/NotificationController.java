package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.notification.NotificationRequest;
import com.portSrilanka.board_admin_backend.dto.notification.NotificationReactionRequest;
import com.portSrilanka.board_admin_backend.dto.notification.NotificationReplyRequest;
import com.portSrilanka.board_admin_backend.dto.notification.NotificationResponse;
import com.portSrilanka.board_admin_backend.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping("/user/{userId}")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER') or hasRole('ADMIN')")
    public ResponseEntity<List<NotificationResponse>> getForUser(@PathVariable Long userId, Authentication authentication) {
        return ResponseEntity.ok(notificationService.getForUser(userId, authentication.getName(), isAdmin(authentication)));
    }

    @PostMapping("/announcement")
    @PreAuthorize("hasRole('SECRETARY')")
    public ResponseEntity<String> createAnnouncement(
            @RequestBody NotificationRequest request,
            Authentication authentication
    ) {
        notificationService.createAnnouncement(request, authentication.getName());
        return ResponseEntity.ok("Announcement sent successfully");
    }

    @PutMapping("/user/{userId}/read")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER') or hasRole('ADMIN')")
    public ResponseEntity<String> markAllRead(@PathVariable Long userId, Authentication authentication) {
        notificationService.markAllRead(userId, authentication.getName(), isAdmin(authentication));
        return ResponseEntity.ok("Notifications marked as read");
    }

    @DeleteMapping("/user/{userId}")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER') or hasRole('ADMIN')")
    public ResponseEntity<String> clearForUser(@PathVariable Long userId, Authentication authentication) {
        notificationService.clearForUser(userId, authentication.getName(), isAdmin(authentication));
        return ResponseEntity.ok("Notifications cleared");
    }

    @PostMapping("/{notificationId}/reply")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER') or hasRole('ADMIN')")
    public ResponseEntity<NotificationResponse> reply(
            @PathVariable Long notificationId,
            @RequestBody NotificationReplyRequest request,
            Authentication authentication
    ) {
        return ResponseEntity.ok(notificationService.reply(notificationId, request, authentication.getName()));
    }

    @PostMapping("/{notificationId}/reaction")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER') or hasRole('ADMIN')")
    public ResponseEntity<NotificationResponse> react(
            @PathVariable Long notificationId,
            @RequestBody NotificationReactionRequest request,
            Authentication authentication
    ) {
        return ResponseEntity.ok(notificationService.react(notificationId, request, authentication.getName()));
    }

    private boolean isAdmin(Authentication authentication) {
        return authentication.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
    }
}

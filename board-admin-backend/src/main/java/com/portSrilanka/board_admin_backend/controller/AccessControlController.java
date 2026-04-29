package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.access.AccessValidationResponse;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.enums.AccessChannel;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import com.portSrilanka.board_admin_backend.security.ChannelAccessService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/access-control")
@RequiredArgsConstructor
public class AccessControlController {

    private final UserRepository userRepository;
    private final ChannelAccessService channelAccessService;

    @GetMapping("/validate/{userId}")
    public ResponseEntity<AccessValidationResponse> validate(
            @PathVariable Long userId,
            @RequestParam AccessChannel channel
    ) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        return ResponseEntity.ok(channelAccessService.validate(user, channel));
    }
}

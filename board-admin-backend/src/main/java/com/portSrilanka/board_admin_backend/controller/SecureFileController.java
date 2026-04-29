package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.security.SecureFileAccessService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/secure-files")
@RequiredArgsConstructor
public class SecureFileController {

    private final SecureFileAccessService secureFileAccessService;

    @GetMapping("/papers/{paperId}")
    public ResponseEntity<String> getPaperFile(
            @PathVariable Long paperId,
            @RequestParam Long userId,
            @RequestParam(defaultValue = "VIEW") String action,
            @RequestParam(defaultValue = "WEB") String channel
    ) {
        return ResponseEntity.ok(
                secureFileAccessService.getAuthorizedPaperPath(paperId, userId, action, channel)
        );
    }
}

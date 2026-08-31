package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.paper.FavoriteResponse;
import com.portSrilanka.board_admin_backend.service.FavoriteService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController @RequestMapping("/api/favorites") @RequiredArgsConstructor
@PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
public class FavoriteController {
    private final FavoriteService service;

    @GetMapping
    public ResponseEntity<List<FavoriteResponse>> list(Authentication authentication) {
        return ResponseEntity.ok(service.list(authentication.getName()));
    }

    @PutMapping("/{type}/{targetId}")
    public ResponseEntity<FavoriteResponse> add(@PathVariable String type,
            @PathVariable Long targetId, Authentication authentication) {
        return ResponseEntity.ok(service.add(type, targetId, authentication.getName()));
    }

    @DeleteMapping("/{type}/{targetId}")
    public ResponseEntity<Void> remove(@PathVariable String type,
            @PathVariable Long targetId, Authentication authentication) {
        service.remove(type, targetId, authentication.getName());
        return ResponseEntity.noContent().build();
    }
}

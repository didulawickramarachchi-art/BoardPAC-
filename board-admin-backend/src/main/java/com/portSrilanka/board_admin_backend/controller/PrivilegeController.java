package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.privilege.*;
import com.portSrilanka.board_admin_backend.service.PrivilegeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/privileges")
@RequiredArgsConstructor
public class PrivilegeController {

    private final PrivilegeService privilegeService;

    @PostMapping
    @PreAuthorize("hasRole('SECRETARY')")
    public ResponseEntity<PrivilegeResponse> assign(@RequestBody PrivilegeAssignRequest request) {
        return ResponseEntity.ok(privilegeService.assign(request));
    }

    @GetMapping
    @PreAuthorize("hasRole('SECRETARY')")
    public ResponseEntity<List<PrivilegeResponse>> getAll() {
        return ResponseEntity.ok(privilegeService.getAll());
    }

    @GetMapping("/user/{userId}")
    @PreAuthorize("hasRole('SECRETARY') or (hasRole('MEMBER') and @privilegeService.isUser(#userId, authentication.name))")
    public ResponseEntity<List<PrivilegeResponse>> getByUser(@PathVariable Long userId) {
        return ResponseEntity.ok(privilegeService.getByUser(userId));
    }

    @DeleteMapping
    @PreAuthorize("hasRole('SECRETARY')")
    public ResponseEntity<String> remove(
            @RequestParam Long userId,
            @RequestParam Long subcategoryId
    ) {
        return ResponseEntity.ok(privilegeService.remove(userId, subcategoryId));
    }
}

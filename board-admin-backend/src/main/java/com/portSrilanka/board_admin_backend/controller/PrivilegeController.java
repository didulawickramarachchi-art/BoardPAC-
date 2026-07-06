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
@PreAuthorize("hasRole('ADMIN')")
public class PrivilegeController {

    private final PrivilegeService privilegeService;

    @PostMapping
    public ResponseEntity<PrivilegeResponse> assign(@RequestBody PrivilegeAssignRequest request) {
        return ResponseEntity.ok(privilegeService.assign(request));
    }

    @GetMapping
    public ResponseEntity<List<PrivilegeResponse>> getAll() {
        return ResponseEntity.ok(privilegeService.getAll());
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<PrivilegeResponse>> getByUser(@PathVariable Long userId) {
        return ResponseEntity.ok(privilegeService.getByUser(userId));
    }

    @DeleteMapping
    public ResponseEntity<String> remove(
            @RequestParam Long userId,
            @RequestParam Long subcategoryId
    ) {
        return ResponseEntity.ok(privilegeService.remove(userId, subcategoryId));
    }
}

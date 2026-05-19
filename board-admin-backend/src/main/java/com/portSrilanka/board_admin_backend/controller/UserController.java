package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.common.PageResponse;
import com.portSrilanka.board_admin_backend.dto.user.*;
import com.portSrilanka.board_admin_backend.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN') or hasRole('SUPPORT_TEAM')")
    public ResponseEntity<List<UserResponse>> getAll() {
        return ResponseEntity.ok(userService.getAllUsers());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN') or hasRole('SUPPORT_TEAM')")
    public ResponseEntity<UserResponse> getById(@PathVariable Long id) {
        return ResponseEntity.ok(userService.getUserById(id));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN')")
    public ResponseEntity<UserResponse> update(@PathVariable Long id, @RequestBody UserRequest request) {
        return ResponseEntity.ok(userService.updateUser(id, request));
    }

    @PutMapping("/{id}/deactivate")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN')")
    public ResponseEntity<String> deactivate(@PathVariable Long id) {
        return ResponseEntity.ok(userService.deactivateUser(id));
    }

    @PutMapping("/{id}/activate")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN')")
    public ResponseEntity<String> activate(@PathVariable Long id) {
        return ResponseEntity.ok(userService.activateUser(id));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN')")
    public ResponseEntity<String> delete(@PathVariable Long id) {
        return ResponseEntity.ok(userService.deleteUser(id));
    }
    @PutMapping("/{id}/reset-password")
@PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN')")
public ResponseEntity<String> resetPassword(@PathVariable Long id) {
    return ResponseEntity.ok(userService.resetPassword(id));
}

@PutMapping("/{id}/lock")
@PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN')")
public ResponseEntity<String> lockUser(@PathVariable Long id) {
    return ResponseEntity.ok(userService.lockUser(id));
}

@PutMapping("/{id}/unlock")
@PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN')")
public ResponseEntity<String> unlockUser(@PathVariable Long id) {
    return ResponseEntity.ok(userService.unlockUser(id));
}
@GetMapping("/paged")
@PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN') or hasRole('SUPPORT_TEAM')")
public ResponseEntity<PageResponse<UserResponse>> getPagedUsers(
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "10") int size,
        @RequestParam(required = false) String search,
        @RequestParam(required = false) com.portSrilanka.board_admin_backend.enums.UserStatus status
) {
    return ResponseEntity.ok(userService.getUsersPaged(page, size, search, status));
}
}

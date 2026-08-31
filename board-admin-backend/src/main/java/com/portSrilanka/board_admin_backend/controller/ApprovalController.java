package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.approval.*;
import com.portSrilanka.board_admin_backend.service.ApprovalService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;

import java.util.List;

@RestController
@RequestMapping("/api/approvals")
@RequiredArgsConstructor
public class ApprovalController {

    private final ApprovalService approvalService;

    @PostMapping
    @PreAuthorize("isAuthenticated() and @accessProfileService.canApprove(authentication.name)")
    public ResponseEntity<ApprovalResponse> approve(@RequestBody ApprovalRequest request, Authentication authentication) {
        return ResponseEntity.ok(approvalService.approve(request, authentication.getName()));
    }

    @GetMapping("/paper/{paperId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<ApprovalResponse>> getByPaper(@PathVariable Long paperId, Authentication authentication) {
        boolean canSeeAll = authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_SECRETARY") || a.getAuthority().equals("ROLE_ADMIN"));
        return ResponseEntity.ok(approvalService.getByPaper(paperId, authentication.getName(), canSeeAll));
    }
}

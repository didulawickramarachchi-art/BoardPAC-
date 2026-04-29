package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.annotation.*;
import com.portSrilanka.board_admin_backend.service.AnnotationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/annotations")
@RequiredArgsConstructor
public class AnnotationController {

    private final AnnotationService annotationService;

    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<AnnotationResponse> create(@RequestBody AnnotationRequest request) {
        return ResponseEntity.ok(annotationService.create(request));
    }

    @GetMapping("/paper/{paperId}/user/{userId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<AnnotationResponse>> getByPaperAndUser(
            @PathVariable Long paperId,
            @PathVariable Long userId
    ) {
        return ResponseEntity.ok(annotationService.getByPaperAndUser(paperId, userId));
    }

    @PostMapping("/backup/{userId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<AnnotationBackupResponse> backup(@PathVariable Long userId) {
        return ResponseEntity.ok(annotationService.backup(userId));
    }

    @PostMapping("/restore")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<String> restore(@RequestBody AnnotationRestoreRequest request) {
        return ResponseEntity.ok(annotationService.restore(request));
    }
}

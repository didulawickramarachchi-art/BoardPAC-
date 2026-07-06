package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.paper.*;
import com.portSrilanka.board_admin_backend.service.AttachmentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/attachments")
@RequiredArgsConstructor
public class AttachmentController {

    private final AttachmentService attachmentService;

    @PostMapping
    @PreAuthorize("hasRole('SECRETARY')")
    public ResponseEntity<PaperAttachmentResponse> add(@RequestBody PaperAttachmentRequest request) {
        return ResponseEntity.ok(attachmentService.addAttachment(request));
    }

    @GetMapping("/paper/{paperId}")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<List<PaperAttachmentResponse>> getByPaper(@PathVariable Long paperId) {
        return ResponseEntity.ok(attachmentService.getAttachments(paperId));
    }
}

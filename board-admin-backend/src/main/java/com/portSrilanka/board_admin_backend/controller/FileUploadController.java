package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.service.SupabaseStorageService;
import com.portSrilanka.board_admin_backend.service.PaperStoragePathService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@RestController
@RequestMapping("/api/files")
@RequiredArgsConstructor
public class FileUploadController {

    private final SupabaseStorageService supabaseStorageService;
    private final PaperStoragePathService paperStoragePathService;

    @PostMapping("/upload")
    @PreAuthorize("hasRole('SECRETARY')")
    public ResponseEntity<Map<String, String>> uploadFile(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "meetingId", required = false) Long meetingId,
            @RequestParam(value = "paperId", required = false) Long paperId) {

        if (file.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "File is empty"));
        }

        try {
            // Category images and other generic uploads do not belong to a
            // meeting or paper. Keep those uploads working while using the
            // structured BoardPaper path when either identifier is supplied.
            String objectPath = meetingId != null || paperId != null
                    ? paperStoragePathService.buildPath(
                            meetingId, paperId, file.getOriginalFilename())
                    : null;
            String fileUrl = supabaseStorageService.uploadFile(file, objectPath);
            if (objectPath == null) {
                return ResponseEntity.ok(Map.of("filePath", fileUrl));
            }
            return ResponseEntity.ok(Map.of("filePath", fileUrl, "objectPath", objectPath));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError()
                .body(Map.of("error", e.getMessage()));
        }
    }
}

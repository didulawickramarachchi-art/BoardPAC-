package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.service.SupabaseStorageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@RestController
@RequestMapping("/api/files")
public class FileUploadController {

    @Autowired
    private SupabaseStorageService supabaseStorageService;

    @PostMapping("/upload")
    @PreAuthorize("hasRole('SECRETARY')")
    public ResponseEntity<Map<String, String>> uploadFile(
            @RequestParam("file") MultipartFile file) {

        if (file.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "File is empty"));
        }

        try {
            String fileUrl = supabaseStorageService.uploadFile(file, null);
            return ResponseEntity.ok(Map.of("filePath", fileUrl));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError()
                .body(Map.of("error", e.getMessage()));
        }
    }
}

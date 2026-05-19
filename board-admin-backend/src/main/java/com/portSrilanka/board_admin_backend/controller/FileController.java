package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.file.FileUploadResponse;
import com.portSrilanka.board_admin_backend.service.FileStorageService;
import io.swagger.v3.oas.annotations.Parameter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/files")
@RequiredArgsConstructor
@PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_SECRETARY')")
public class FileController {

    private final FileStorageService fileStorageService;

    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<FileUploadResponse> upload(
            @Parameter(description = "File to upload", required = true)
            @RequestPart("file") MultipartFile file
    ) throws Exception {
        return ResponseEntity.ok(fileStorageService.upload(file));
    }
}

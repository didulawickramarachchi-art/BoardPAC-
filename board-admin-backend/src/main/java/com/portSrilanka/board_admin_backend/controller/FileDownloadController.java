package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.service.FileStorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.nio.file.Files;

@RestController
@RequestMapping("/api/files")
@RequiredArgsConstructor
public class FileDownloadController {

    private final FileStorageService fileStorageService;

    @GetMapping("/content/{token}")
    public ResponseEntity<Resource> content(@PathVariable String token) throws IOException {
        return serve(token, false);
    }

    @GetMapping("/public/{token}")
    public ResponseEntity<Resource> publicContent(@PathVariable String token) throws IOException {
        return serve(token, true);
    }

    private ResponseEntity<Resource> serve(String token, boolean publicOnly) throws IOException {
        Resource resource;
        try {
            resource = fileStorageService.load(token, publicOnly);
        } catch (IOException e) {
            if (e instanceof FileNotFoundException) return ResponseEntity.notFound().build();
            return ResponseEntity.badRequest().build();
        }
        String type = Files.probeContentType(resource.getFile().toPath());
        MediaType mediaType;
        try {
            mediaType = type == null ? MediaType.APPLICATION_OCTET_STREAM : MediaType.parseMediaType(type);
        } catch (Exception e) {
            mediaType = MediaType.APPLICATION_OCTET_STREAM;
        }
        return ResponseEntity.ok()
                .contentType(mediaType)
                .header("X-Content-Type-Options", "nosniff")
                .body(resource);
    }
}

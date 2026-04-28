package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.file.FileUploadResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.*;
import java.util.UUID;

@Service
public class FileStorageService {

    @Value("${app.file.upload-dir}")
    private String uploadDir;

    public FileUploadResponse upload(MultipartFile file) throws IOException {
        Path uploadPath = Paths.get(uploadDir);
        if (!Files.exists(uploadPath)) {
            Files.createDirectories(uploadPath);
        }

        String original = file.getOriginalFilename() == null ? "file" : file.getOriginalFilename();
        String fileName = UUID.randomUUID() + "_" + original.replaceAll("\\s+", "_");
        Path target = uploadPath.resolve(fileName);

        Files.copy(file.getInputStream(), target, StandardCopyOption.REPLACE_EXISTING);

        return FileUploadResponse.builder()
                .fileName(fileName)
                .filePath(target.toString())
                .build();
    }
}

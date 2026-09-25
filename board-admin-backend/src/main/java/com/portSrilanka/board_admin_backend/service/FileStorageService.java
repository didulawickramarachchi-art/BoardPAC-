package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.file.FileUploadResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.*;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;
import java.util.UUID;

@Service
public class FileStorageService {

    private final Path root;

    public FileStorageService(@Value("${app.file.upload-dir}") String uploadDir) {
        this.root = Paths.get(uploadDir).toAbsolutePath().normalize();
    }

    public FileUploadResponse upload(MultipartFile file) throws IOException {
        String fileName = UUID.randomUUID() + "_" + safeName(file.getOriginalFilename());
        String url = uploadFile(file, "uploads/" + fileName);
        return FileUploadResponse.builder()
                .fileName(fileName)
                .filePath(url)
                .build();
    }

    public String uploadFile(MultipartFile file, String objectPath) throws IOException {
        if (file == null || file.isEmpty()) throw new IllegalArgumentException("File is empty");
        String path = objectPath == null || objectPath.isBlank()
                ? "uploads/" + UUID.randomUUID() + "_" + safeName(file.getOriginalFilename())
                : objectPath;
        Path target = resolve(path);
        Files.createDirectories(target.getParent());
        try (var input = file.getInputStream()) {
            Files.copy(input, target, StandardCopyOption.REPLACE_EXISTING);
        }
        String token = Base64.getUrlEncoder().withoutPadding()
                .encodeToString(path.getBytes(StandardCharsets.UTF_8));
        String route = path.startsWith("profile-pictures/") ? "/api/files/public/" : "/api/files/content/";
        return ServletUriComponentsBuilder.fromCurrentContextPath().path(route).path(token).toUriString();
    }

    public Resource load(String token, boolean publicOnly) throws IOException {
        String path;
        try {
            path = new String(Base64.getUrlDecoder().decode(token), StandardCharsets.UTF_8);
        } catch (IllegalArgumentException e) {
            throw new IOException("Invalid file identifier", e);
        }
        if (publicOnly && !path.startsWith("profile-pictures/")) throw new IOException("File is not public");
        Path target = resolve(path);
        if (!Files.isRegularFile(target)) throw new java.io.FileNotFoundException("File not found");
        return new UrlResource(target.toUri());
    }

    private Path resolve(String path) throws IOException {
        if (path == null || path.isBlank() || path.indexOf('\\') >= 0 || path.indexOf('\0') >= 0) {
            throw new IOException("Invalid file path");
        }
        Path relative = Paths.get(path);
        if (relative.isAbsolute() || relative.normalize().startsWith("..")) throw new IOException("Invalid file path");
        for (Path segment : relative) {
            if (segment.toString().equals("..") || segment.toString().equals(".")) throw new IOException("Invalid file path");
        }
        Path target = root.resolve(relative).normalize();
        if (!target.startsWith(root) || target.equals(root)) throw new IOException("Invalid file path");
        return target;
    }

    private String safeName(String original) {
        String name = original == null ? "file" : original.replace('\\', '/');
        name = name.substring(name.lastIndexOf('/') + 1).replaceAll("[^a-zA-Z0-9._-]", "_");
        return name.isBlank() || name.equals(".") || name.equals("..") ? "file" : name;
    }
}

package com.portSrilanka.board_admin_backend.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.UUID;

@Service
public class SupabaseStorageService {

    private static final int CONNECT_TIMEOUT_MS = 8_000;
    private static final int READ_TIMEOUT_MS = 12_000;

    @Value("${supabase.url:}")
    private String supabaseUrl;

    @Value("${supabase.key:}")
    private String supabaseKey;

    @Value("${supabase.bucket:Files}")
    private String bucket;

    public String uploadFile(MultipartFile file, String path) throws IOException {
        return uploadFile(file, path, bucket);
    }

    public String uploadFile(MultipartFile file, String path, String targetBucket) throws IOException {
        if (supabaseUrl == null || supabaseUrl.isBlank() || supabaseKey == null || supabaseKey.isBlank()) {
            throw new IllegalStateException("SUPABASE_URL or SUPABASE_KEY not set in environment variables or application properties");
        }

        if (targetBucket == null || targetBucket.isBlank()) {
            throw new IllegalArgumentException("Storage bucket is missing");
        }

        String filename = (path != null && !path.isBlank())
                ? path
                : uniqueGenericPath(file.getOriginalFilename());
        if (filename == null || filename.isBlank()) {
            throw new IllegalArgumentException("File name missing");
        }

        IOException firstFailure;
        try {
            return uploadOnce(file, filename, targetBucket);
        } catch (IOException exception) {
            firstFailure = exception;
        }

        try {
            return uploadOnce(file, filename, targetBucket);
        } catch (IOException exception) {
            exception.addSuppressed(firstFailure);
            throw exception;
        }
    }

    private String uploadOnce(MultipartFile file, String filename, String targetBucket) throws IOException {

        String encoded = encodeObjectPath(filename);
        String encodedBucket = URLEncoder.encode(targetBucket, StandardCharsets.UTF_8).replace("+", "%20");
        String urlStr = supabaseUrl + "/storage/v1/object/" + encodedBucket + "/" + encoded;

        URL url = new URL(urlStr);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        try {
            conn.setConnectTimeout(CONNECT_TIMEOUT_MS);
            conn.setReadTimeout(READ_TIMEOUT_MS);
            conn.setDoOutput(true);
            conn.setRequestMethod("PUT");
            conn.setRequestProperty("apikey", supabaseKey);
            if (!supabaseKey.startsWith("sb_")) {
                conn.setRequestProperty("Authorization", "Bearer " + supabaseKey);
            }
            String contentType = (file.getContentType() == null) ? "application/octet-stream" : file.getContentType();
            conn.setRequestProperty("Content-Type", contentType);
            conn.setRequestProperty("x-upsert", "true");
            conn.setFixedLengthStreamingMode(file.getSize());

            try (OutputStream out = conn.getOutputStream(); InputStream in = file.getInputStream()) {
                byte[] buffer = new byte[8192];
                int read;
                while ((read = in.read(buffer)) != -1) {
                    out.write(buffer, 0, read);
                }
            }

            int resp = conn.getResponseCode();
            if (resp >= 200 && resp < 300) {
                return supabaseUrl + "/storage/v1/object/public/" + encodedBucket + "/" + encoded;
            } else {
                String body = "";
                try (InputStream err = conn.getErrorStream()) {
                    if (err != null) body = new String(err.readAllBytes(), StandardCharsets.UTF_8);
                }
                throw new IOException("Upload failed: HTTP " + resp + " - " + body);
            }
        } finally {
            conn.disconnect();
        }
    }

    private String uniqueGenericPath(String originalFilename) {
        String name = originalFilename == null ? "image" : originalFilename;
        name = name.replaceAll("[^a-zA-Z0-9._-]", "_");
        return "uploads/" + UUID.randomUUID() + "-" + name;
    }

    private String encodeObjectPath(String path) {
        return java.util.Arrays.stream(path.split("/"))
                .map(segment -> URLEncoder.encode(segment, StandardCharsets.UTF_8).replace("+", "%20"))
                .collect(java.util.stream.Collectors.joining("/"));
    }
}

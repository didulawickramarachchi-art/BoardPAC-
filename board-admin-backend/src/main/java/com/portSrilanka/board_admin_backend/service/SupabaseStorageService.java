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

@Service
public class SupabaseStorageService {

    @Value("${supabase.url:}")
    private String supabaseUrl;

    @Value("${supabase.key:}")
    private String supabaseKey;

    @Value("${supabase.bucket:Files}")
    private String bucket;

    public String uploadFile(MultipartFile file, String path) throws IOException {
        if (supabaseUrl == null || supabaseUrl.isBlank() || supabaseKey == null || supabaseKey.isBlank()) {
            throw new IllegalStateException("SUPABASE_URL or SUPABASE_KEY not set in environment variables or application properties");
        }

        String filename = (path != null && !path.isBlank()) ? path : file.getOriginalFilename();
        if (filename == null || filename.isBlank()) {
            throw new IllegalArgumentException("File name missing");
        }

        String encoded = URLEncoder.encode(filename, StandardCharsets.UTF_8.toString()).replace("+", "%20");
        String urlStr = supabaseUrl + "/storage/v1/object/" + bucket + "/" + encoded;

        URL url = new URL(urlStr);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setDoOutput(true);
        conn.setRequestMethod("PUT");
        conn.setRequestProperty("apikey", supabaseKey);
        if (!supabaseKey.startsWith("sb_")) {
            conn.setRequestProperty("Authorization", "Bearer " + supabaseKey);
        }
        String contentType = (file.getContentType() == null) ? "application/octet-stream" : file.getContentType();
        conn.setRequestProperty("Content-Type", contentType);
        conn.setRequestProperty("x-upsert", "true");

        try (OutputStream out = conn.getOutputStream(); InputStream in = file.getInputStream()) {
            byte[] buffer = new byte[8192];
            int read;
            while ((read = in.read(buffer)) != -1) {
                out.write(buffer, 0, read);
            }
        }

        int resp = conn.getResponseCode();
        if (resp >= 200 && resp < 300) {
            return supabaseUrl + "/storage/v1/object/public/" + bucket + "/" + encoded;
        } else {
            String body = "";
            try (InputStream err = conn.getErrorStream()) {
                if (err != null) body = new String(err.readAllBytes(), StandardCharsets.UTF_8);
            }
            throw new IOException("Upload failed: HTTP " + resp + " - " + body);
        }
    }
}

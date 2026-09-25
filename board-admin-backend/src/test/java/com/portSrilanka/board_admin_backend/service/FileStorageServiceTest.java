package com.portSrilanka.board_admin_backend.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.Base64;

import static org.junit.jupiter.api.Assertions.*;

class FileStorageServiceTest {
    @TempDir Path directory;

    @Test
    void storesAndLoadsFileAndKeepsOtherFilesPrivate() throws Exception {
        FileStorageService storage = new FileStorageService(directory.toString());
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setScheme("http");
        request.setServerName("localhost");
        request.setServerPort(8081);
        RequestContextHolder.setRequestAttributes(new ServletRequestAttributes(request));
        try {
            String url = storage.uploadFile(new MockMultipartFile("file", "board.pdf", "application/pdf",
                    "paper".getBytes(StandardCharsets.UTF_8)), "papers/board.pdf");
            String token = url.substring(url.lastIndexOf('/') + 1);
            assertTrue(url.contains("/api/files/content/"));
            try (var input = storage.load(token, false).getInputStream()) {
                assertEquals("paper", new String(input.readAllBytes(), StandardCharsets.UTF_8));
            }
            assertThrows(IOException.class, () -> storage.load(token, true));
            String traversal = Base64.getUrlEncoder().withoutPadding().encodeToString(
                    "profile-pictures/../papers/board.pdf".getBytes(StandardCharsets.UTF_8));
            assertThrows(IOException.class, () -> storage.load(traversal, true));
        } finally {
            RequestContextHolder.resetRequestAttributes();
        }
    }
}

package com.portSrilanka.board_admin_backend.dto.file;

import lombok.*;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class FileUploadResponse {
    private String fileName;
    private String filePath;
}

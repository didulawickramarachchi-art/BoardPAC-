package com.portSrilanka.board_admin_backend.dto.paper;

import lombok.Data;

@Data
public class PaperAttachmentRequest {
    private Long paperId;
    private String fileName;
    private String filePath;
    private Integer displayOrder;
}
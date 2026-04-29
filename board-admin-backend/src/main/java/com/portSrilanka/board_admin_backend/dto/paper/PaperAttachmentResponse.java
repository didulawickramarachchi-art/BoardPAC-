package com.portSrilanka.board_admin_backend.dto.paper;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class PaperAttachmentResponse {
    private Long id;
    private Long paperId;
    private String fileName;
    private String filePath;
    private Integer displayOrder;
}
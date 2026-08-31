package com.portSrilanka.board_admin_backend.dto.paper;

import com.portSrilanka.board_admin_backend.enums.PaperType;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class PaperResponse {
    private Long id;
    private Long agendaItemId;
    private String title;
    private PaperType paperType;
    private String referenceNumber;
    private String filePath;
    private String fileName;
    private Integer versionNumber;
    private boolean requiresApproval;
    private boolean isMainPaper;
    private Long rootPaperId;
    private boolean currentVersion;
    private String revisionNote;
    private java.time.LocalDateTime createdAt;
}

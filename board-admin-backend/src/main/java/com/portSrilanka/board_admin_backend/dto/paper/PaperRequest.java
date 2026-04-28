package com.portSrilanka.board_admin_backend.dto.paper;

import com.portSrilanka.board_admin_backend.enums.PaperType;
import lombok.Data;

@Data
public class PaperRequest {
    private Long meetingId;
    private Long agendaItemId;
    private PaperType paperType;
    private String title;
    private String referenceNumber;
    private String filePath;
    private String fileName;
    private Integer versionNumber;
    private boolean requiresApproval;
    private boolean isMainPaper;
    private String disclaimerMessage;
}

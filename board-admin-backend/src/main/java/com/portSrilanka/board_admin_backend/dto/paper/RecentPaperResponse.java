package com.portSrilanka.board_admin_backend.dto.paper;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data @Builder
public class RecentPaperResponse {
    private Long paperId;
    private String title;
    private String paperType;
    private String filePath;
    private String fileName;
    private Integer versionNumber;
    private boolean requiresApproval;
    private boolean mainPaper;
    private Long agendaItemId;
    private Integer lastPage;
    private Integer totalPages;
    private boolean completed;
    private LocalDateTime lastOpenedAt;
}

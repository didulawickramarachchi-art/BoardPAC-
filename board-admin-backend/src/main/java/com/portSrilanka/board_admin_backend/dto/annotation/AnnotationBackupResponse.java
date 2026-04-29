package com.portSrilanka.board_admin_backend.dto.annotation;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class AnnotationBackupResponse {
    private Long backupId;
    private Long userId;
    private Integer annotationCount;
    private String backupJson;
}

package com.portSrilanka.board_admin_backend.dto.annotation;

import lombok.Data;

@Data
public class AnnotationRestoreRequest {
    private Long backupId;
    private Long userId;
}

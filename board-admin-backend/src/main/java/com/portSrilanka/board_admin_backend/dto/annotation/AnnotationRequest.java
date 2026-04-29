package com.portSrilanka.board_admin_backend.dto.annotation;

import com.portSrilanka.board_admin_backend.enums.AnnotationType;
import lombok.Data;

@Data
public class AnnotationRequest {
    private Long paperId;
    private Long userId;
    private AnnotationType annotationType;
    private String annotationDataJson;
    private Integer pageNumber;
}

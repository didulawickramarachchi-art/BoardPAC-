package com.portSrilanka.board_admin_backend.dto.annotation;

import com.portSrilanka.board_admin_backend.enums.AnnotationType;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class AnnotationResponse {
    private Long id;
    private Long paperId;
    private Long userId;
    private AnnotationType annotationType;
    private String annotationDataJson;
    private Integer pageNumber;
}

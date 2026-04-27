package com.portSrilanka.board_admin_backend.dto.category;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class CategoryResponse {
    private Long id;
    private String name;
    private String displayName;
    private Integer displayOrder;
}
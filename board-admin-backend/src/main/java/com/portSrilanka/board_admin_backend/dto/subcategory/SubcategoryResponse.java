package com.portSrilanka.board_admin_backend.dto.subcategory;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class SubcategoryResponse {
    private Long id;
    private String name;
    private String displayName;
    private Integer displayOrder;
    private Long categoryId;
    private String categoryName;
}
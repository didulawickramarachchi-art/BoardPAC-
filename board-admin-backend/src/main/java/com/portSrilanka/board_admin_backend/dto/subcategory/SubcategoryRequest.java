package com.portSrilanka.board_admin_backend.dto.subcategory;

import lombok.Data;

@Data
public class SubcategoryRequest {
    private String name;
    private String displayName;
    private Integer displayOrder;
    private Long categoryId;
}
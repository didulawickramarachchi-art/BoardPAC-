package com.portSrilanka.board_admin_backend.dto.category;

import lombok.Data;

@Data
public class CategoryRequest {
    private String name;
    private String displayName;
    private Integer displayOrder;
}

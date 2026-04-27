package com.portSrilanka.board_admin_backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "subcategories")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Subcategory extends BaseEntity {

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String displayName;

    private Integer displayOrder;

    @ManyToOne
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;
}
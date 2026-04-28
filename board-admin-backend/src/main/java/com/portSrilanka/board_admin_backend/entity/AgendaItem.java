package com.portSrilanka.board_admin_backend.entity;

import com.portSrilanka.board_admin_backend.enums.AgendaItemType;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "agenda_items")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AgendaItem extends BaseEntity {

    @ManyToOne
    @JoinColumn(name = "meeting_id", nullable = false)
    private Meeting meeting;

    @ManyToOne
    @JoinColumn(name = "section_id")
    private AgendaSection section;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AgendaItemType itemType;

    @Column(nullable = false)
    private String title;

    private String numberLabel;
    private Integer displayOrder;

    @Column(length = 3000)
    private String description;

    private String mediaPath;
}

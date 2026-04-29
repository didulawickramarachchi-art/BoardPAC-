package com.portSrilanka.board_admin_backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "shared_agenda_items")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SharedAgendaItem extends BaseEntity {

    @ManyToOne
    @JoinColumn(name = "source_agenda_item_id", nullable = false)
    private AgendaItem sourceAgendaItem;

    @ManyToOne
    @JoinColumn(name = "source_subcategory_id", nullable = false)
    private Subcategory sourceSubcategory;

    @ManyToOne
    @JoinColumn(name = "target_subcategory_id", nullable = false)
    private Subcategory targetSubcategory;

    @ManyToOne
    @JoinColumn(name = "shared_by", nullable = false)
    private User sharedBy;

    private boolean active;
}
package com.portSrilanka.board_admin_backend.entity;

import com.portSrilanka.board_admin_backend.enums.PaperType;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "papers")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Paper extends BaseEntity {

    @ManyToOne
    @JoinColumn(name = "meeting_id", nullable = false)
    private Meeting meeting;

    @ManyToOne
    @JoinColumn(name = "agenda_item_id", nullable = false)
    private AgendaItem agendaItem;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PaperType paperType;

    @Column(nullable = false)
    private String title;

    private String referenceNumber;
    private String filePath;
    private String fileName;
    private Integer versionNumber;
    private boolean requiresApproval;
    private boolean isMainPaper;

    @Column(length = 2000)
    private String disclaimerMessage;
}

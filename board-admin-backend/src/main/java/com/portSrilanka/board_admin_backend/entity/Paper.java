package com.portSrilanka.board_admin_backend.entity;

import com.portSrilanka.board_admin_backend.enums.PaperType;
import jakarta.persistence.*;
import lombok.*;

import java.util.List;

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
    @JoinColumn(name = "agenda_item_id")
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

    @OneToMany(mappedBy = "paper", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<PaperAttachment> attachments;

    @OneToMany(mappedBy = "paper", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<PaperApproval> approvals;

    @OneToMany(mappedBy = "paper", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<PaperShare> shares;

    @OneToMany(mappedBy = "paper", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Annotation> annotations;

    @OneToMany(mappedBy = "paper", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Comment> comments;
}

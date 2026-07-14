package com.portSrilanka.board_admin_backend.entity;

import com.portSrilanka.board_admin_backend.enums.ReactionType;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "attachment_reactions",
        uniqueConstraints = @UniqueConstraint(columnNames = {"attachment_id", "user_id"}))
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AttachmentReaction extends BaseEntity {
    @ManyToOne(optional = false)
    @JoinColumn(name = "attachment_id", nullable = false)
    private PaperAttachment attachment;

    @ManyToOne(optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ReactionType reactionType;
}

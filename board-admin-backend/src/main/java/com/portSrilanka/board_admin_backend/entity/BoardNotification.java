package com.portSrilanka.board_admin_backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "notifications")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BoardNotification extends BaseEntity {

    @Column(nullable = false)
    private String title;

    @Column(nullable = false, length = 3000)
    private String message;

    @Column(nullable = false)
    private String type;

    @ManyToOne
    @JoinColumn(name = "recipient_id", nullable = false)
    private User recipient;

    @ManyToOne
    @JoinColumn(name = "created_by")
    private User createdBy;

    private Long relatedMeetingId;
    private Long relatedPaperId;
    private Long relatedCommentId;
    private Long relatedAttachmentId;

    @Column(nullable = false)
    private boolean announcement;

    @Column(name = "is_read", nullable = false)
    private boolean read;
}

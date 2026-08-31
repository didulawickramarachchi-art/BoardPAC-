package com.portSrilanka.board_admin_backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity @Table(name = "meeting_minutes", uniqueConstraints =
        @UniqueConstraint(columnNames = {"meeting_id", "version_number"}))
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class MeetingMinutes extends BaseEntity {
    @ManyToOne(optional = false) @JoinColumn(name = "meeting_id", nullable = false)
    private Meeting meeting;
    @Column(name = "version_number", nullable = false)
    private Integer versionNumber;
    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;
    @Column(nullable = false)
    private String status;
    @ManyToOne(optional = false) @JoinColumn(name = "created_by", nullable = false)
    private User createdBy;
    @ManyToOne @JoinColumn(name = "reviewed_by")
    private User reviewedBy;
    @Column(columnDefinition = "TEXT")
    private String reviewComment;
    private LocalDateTime publishedAt;
}

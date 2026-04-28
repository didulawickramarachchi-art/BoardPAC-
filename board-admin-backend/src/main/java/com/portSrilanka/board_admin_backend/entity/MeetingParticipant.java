package com.portSrilanka.board_admin_backend.entity;

import com.portSrilanka.board_admin_backend.enums.ParticipantStatus;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "meeting_participants",
       uniqueConstraints = @UniqueConstraint(columnNames = {"meeting_id", "user_id"}))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MeetingParticipant extends BaseEntity {

    @ManyToOne
    @JoinColumn(name = "meeting_id", nullable = false)
    private Meeting meeting;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ParticipantStatus participantStatus;

    @Column(length = 1000)
    private String statusReason;

    private Integer displaySequence;
}


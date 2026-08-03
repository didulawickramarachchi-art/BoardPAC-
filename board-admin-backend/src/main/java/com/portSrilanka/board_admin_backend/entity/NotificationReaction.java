package com.portSrilanka.board_admin_backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(
        name = "notification_reactions",
        uniqueConstraints = @UniqueConstraint(columnNames = {"notification_id", "user_id"})
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationReaction extends BaseEntity {

    @ManyToOne
    @JoinColumn(name = "notification_id", nullable = false)
    private BoardNotification notification;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private String reactionType;
}

package com.portSrilanka.board_admin_backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "notification_replies")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationReply extends BaseEntity {

    @ManyToOne
    @JoinColumn(name = "notification_id", nullable = false)
    private BoardNotification notification;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 2000)
    private String message;
}

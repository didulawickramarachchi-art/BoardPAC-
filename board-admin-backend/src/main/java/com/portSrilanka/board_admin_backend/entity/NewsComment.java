package com.portSrilanka.board_admin_backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity @Table(name = "news_comments")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class NewsComment extends BaseEntity {
    @ManyToOne @JoinColumn(name = "post_id", nullable = false) private NewsPost post;
    @ManyToOne @JoinColumn(name = "user_id", nullable = false) private User user;
    @Column(nullable = false, length = 2000) private String message;
}

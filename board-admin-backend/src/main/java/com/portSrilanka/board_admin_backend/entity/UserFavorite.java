package com.portSrilanka.board_admin_backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "user_favorites", uniqueConstraints =
        @UniqueConstraint(columnNames = {"user_id", "favorite_type", "target_id"}))
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UserFavorite extends BaseEntity {
    @ManyToOne(optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "favorite_type", nullable = false)
    private String favoriteType;

    @Column(name = "target_id", nullable = false)
    private Long targetId;
}

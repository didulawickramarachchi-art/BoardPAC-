package com.portSrilanka.board_admin_backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "comment_shares")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CommentShare extends BaseEntity {

    @ManyToOne
    @JoinColumn(name = "comment_id", nullable = false)
    private Comment comment;

    @ManyToOne
    @JoinColumn(name = "shared_by", nullable = false)
    private User sharedBy;

    @ManyToOne
    @JoinColumn(name = "shared_to", nullable = false)
    private User sharedTo;
}

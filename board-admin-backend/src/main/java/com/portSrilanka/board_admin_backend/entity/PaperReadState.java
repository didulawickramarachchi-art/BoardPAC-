package com.portSrilanka.board_admin_backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "paper_read_states", uniqueConstraints =
        @UniqueConstraint(columnNames = {"paper_id", "user_id"}))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PaperReadState extends BaseEntity {
    @ManyToOne(optional = false)
    @JoinColumn(name = "paper_id", nullable = false)
    private Paper paper;

    @ManyToOne(optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private LocalDateTime firstOpenedAt;

    @Column(nullable = false)
    private LocalDateTime lastOpenedAt;

    @Column(nullable = false)
    private Integer lastPage;

    private Integer totalPages;

    @Column(nullable = false)
    private boolean completed;
}

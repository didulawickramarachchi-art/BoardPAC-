package com.portSrilanka.board_admin_backend.entity;

import com.portSrilanka.board_admin_backend.enums.ApprovalStatus;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "paper_approvals",
       uniqueConstraints = @UniqueConstraint(columnNames = {"paper_id", "user_id"}))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PaperApproval extends BaseEntity {

    @ManyToOne
    @JoinColumn(name = "paper_id", nullable = false)
    private Paper paper;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ApprovalStatus approvalStatus;

    @Column(length = 2000)
    private String approvalComment;
}

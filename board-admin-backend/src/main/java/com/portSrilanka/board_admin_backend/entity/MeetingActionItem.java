package com.portSrilanka.board_admin_backend.entity;
import com.portSrilanka.board_admin_backend.enums.ActionItemStatus;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;

@Entity @Table(name="meeting_action_items") @Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class MeetingActionItem extends BaseEntity {
    @ManyToOne @JoinColumn(name="meeting_id",nullable=false) private Meeting meeting;
    @Column(nullable=false,length=300) private String title;
    @Column(length=2000) private String description;
    @ManyToOne @JoinColumn(name="assignee_id",nullable=false) private User assignee;
    @ManyToOne @JoinColumn(name="created_by",nullable=false) private User createdBy;
    private LocalDate dueDate;
    @Enumerated(EnumType.STRING) @Column(nullable=false) @Builder.Default private ActionItemStatus status=ActionItemStatus.OPEN;
    @Column(length=2000) private String completionNote;
}

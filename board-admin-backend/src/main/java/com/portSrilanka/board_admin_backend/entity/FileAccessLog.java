package com.portSrilanka.board_admin_backend.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "file_access_logs")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FileAccessLog extends BaseEntity {

    @ManyToOne
    @JoinColumn(name = "paper_id")
    private Paper paper;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    private String actionName;
    private String fileName;
    private LocalDateTime actionTime;
    private String channel;
}

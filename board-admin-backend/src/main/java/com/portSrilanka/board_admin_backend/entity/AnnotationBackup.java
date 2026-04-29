package com.portSrilanka.board_admin_backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "annotation_backups")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AnnotationBackup extends BaseEntity {

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(length = 100000, nullable = false)
    private String backupJson;

    private Integer annotationCount;
}

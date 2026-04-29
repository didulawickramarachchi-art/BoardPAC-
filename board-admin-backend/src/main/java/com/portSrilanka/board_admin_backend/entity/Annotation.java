package com.portSrilanka.board_admin_backend.entity;

import com.portSrilanka.board_admin_backend.enums.AnnotationType;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "annotations")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Annotation extends BaseEntity {

    @ManyToOne
    @JoinColumn(name = "paper_id", nullable = false)
    private Paper paper;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AnnotationType annotationType;

    @Column(length = 5000, nullable = false)
    private String annotationDataJson;

    private Integer pageNumber;
}

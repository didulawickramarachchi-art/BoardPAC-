package com.portSrilanka.board_admin_backend.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;

@Entity
@Table(name = "issue_reports")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class IssueReport extends BaseEntity {

    private LocalDate issueOccurredDate;

    @Column(length = 3000)
    private String issueDescription;

    private String username;
    private String screenshotPath;
    private boolean attachLogFiles;
    private boolean attachProductSettings;
    private boolean attachErrorData;

    @Column(length = 1000)
    private String otherResources;
}

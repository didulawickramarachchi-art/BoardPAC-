package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.IssueReport;
import org.springframework.data.jpa.repository.JpaRepository;

public interface IssueReportRepository extends JpaRepository<IssueReport, Long> {
}

package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.Paper;
import com.portSrilanka.board_admin_backend.enums.ApprovalStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface PaperRepository extends JpaRepository<Paper, Long> {
    @org.springframework.data.jpa.repository.Query("select p from Paper p where p.id = :rootId or p.rootPaper.id = :rootId order by p.versionNumber desc")
    List<Paper> findVersionHistory(Long rootId);
    List<Paper> findByMeetingId(Long meetingId);
    List<Paper> findByAgendaItemId(Long agendaItemId);
    Optional<Paper> findByReferenceNumber(String referenceNumber);

    @Query("""
            select count(p) from Paper p
            where p.meeting.id in :meetingIds
              and p.requiresApproval = true
              and p.currentVersion = true
              and not exists (
                  select a.id from PaperApproval a
                  where a.paper = p
                    and a.user.id = :userId
                    and a.approvalStatus in :finalStatuses
              )
            """)
    long countPendingApprovalsForUser(
            @Param("userId") Long userId,
            @Param("meetingIds") Collection<Long> meetingIds,
            @Param("finalStatuses") Collection<ApprovalStatus> finalStatuses
    );
    
}

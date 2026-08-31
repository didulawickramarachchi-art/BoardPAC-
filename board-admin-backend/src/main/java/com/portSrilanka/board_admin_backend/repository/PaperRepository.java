package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.Paper;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PaperRepository extends JpaRepository<Paper, Long> {
    @org.springframework.data.jpa.repository.Query("select p from Paper p where p.id = :rootId or p.rootPaper.id = :rootId order by p.versionNumber desc")
    List<Paper> findVersionHistory(Long rootId);
    List<Paper> findByMeetingId(Long meetingId);
    List<Paper> findByAgendaItemId(Long agendaItemId);
    Optional<Paper> findByReferenceNumber(String referenceNumber);
    
}

package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.AgendaSection;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AgendaSectionRepository extends JpaRepository<AgendaSection, Long> {
    List<AgendaSection> findByMeetingIdOrderByDisplayOrderAsc(Long meetingId);
}

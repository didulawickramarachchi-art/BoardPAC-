package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.AgendaItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AgendaItemRepository extends JpaRepository<AgendaItem, Long> {
    List<AgendaItem> findByMeetingIdOrderByDisplayOrderAsc(Long meetingId);
    List<AgendaItem> findBySectionId(Long sectionId);
}

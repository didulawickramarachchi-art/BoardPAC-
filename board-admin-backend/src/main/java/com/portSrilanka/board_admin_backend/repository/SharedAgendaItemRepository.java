package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.SharedAgendaItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SharedAgendaItemRepository extends JpaRepository<SharedAgendaItem, Long> {
    List<SharedAgendaItem> findByTargetSubcategoryIdAndActiveTrue(Long targetSubcategoryId);
    List<SharedAgendaItem> findBySourceAgendaItemId(Long sourceAgendaItemId);
}
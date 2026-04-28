package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.Meeting;
import com.portSrilanka.board_admin_backend.enums.MeetingType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MeetingRepository extends JpaRepository<Meeting, Long> {
    List<Meeting> findBySubcategoryId(Long subcategoryId);
    List<Meeting> findByType(MeetingType type);
}

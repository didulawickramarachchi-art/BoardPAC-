package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.MeetingMinutes;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;

public interface MeetingMinutesRepository extends JpaRepository<MeetingMinutes, Long> {
    List<MeetingMinutes> findByMeetingIdOrderByVersionNumberDesc(Long meetingId);
    Optional<MeetingMinutes> findTopByMeetingIdOrderByVersionNumberDesc(Long meetingId);
}

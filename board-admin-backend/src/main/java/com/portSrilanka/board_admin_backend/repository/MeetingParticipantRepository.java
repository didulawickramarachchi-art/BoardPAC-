package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.MeetingParticipant;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface MeetingParticipantRepository extends JpaRepository<MeetingParticipant, Long> {
    List<MeetingParticipant> findByMeetingIdOrderByDisplaySequenceAsc(Long meetingId);
    Optional<MeetingParticipant> findByMeetingIdAndUserId(Long meetingId, Long userId);
}

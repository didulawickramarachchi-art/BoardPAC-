package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.MeetingParticipant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface MeetingParticipantRepository extends JpaRepository<MeetingParticipant, Long> {
    List<MeetingParticipant> findByMeetingIdOrderByDisplaySequenceAsc(Long meetingId);
    Optional<MeetingParticipant> findByMeetingIdAndUserId(Long meetingId, Long userId);

    @Query("select participant.meeting.id from MeetingParticipant participant where participant.user.id = :userId")
    List<Long> findMeetingIdsByUserId(@Param("userId") Long userId);
}

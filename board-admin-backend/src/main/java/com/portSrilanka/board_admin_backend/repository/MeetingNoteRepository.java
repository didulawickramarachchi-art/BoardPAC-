package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.MeetingNote;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MeetingNoteRepository extends JpaRepository<MeetingNote, Long> {
    List<MeetingNote> findByMeetingIdAndUserId(Long meetingId, Long userId);
}

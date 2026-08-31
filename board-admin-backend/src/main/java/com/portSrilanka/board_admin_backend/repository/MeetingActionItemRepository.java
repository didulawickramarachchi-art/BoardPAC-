package com.portSrilanka.board_admin_backend.repository;
import com.portSrilanka.board_admin_backend.entity.MeetingActionItem;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
public interface MeetingActionItemRepository extends JpaRepository<MeetingActionItem,Long>{List<MeetingActionItem> findByMeetingIdOrderByDueDateAscCreatedAtDesc(Long meetingId);}

package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.Meeting;
import com.portSrilanka.board_admin_backend.enums.MeetingType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Set;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface MeetingRepository extends JpaRepository<Meeting, Long> {
    List<Meeting> findBySubcategoryId(Long subcategoryId);
    List<Meeting> findByType(MeetingType type);
    long countByType(MeetingType type);

    @Query("""
            select distinct meeting from Meeting meeting
            join meeting.participants participant
            where participant.user.id = :userId
              and meeting.subcategory.id in :subcategoryIds
            order by meeting.meetingDateTime asc
            """)
    List<Meeting> findVisibleForMember(
            @Param("userId") Long userId,
            @Param("subcategoryIds") Set<Long> subcategoryIds);
}

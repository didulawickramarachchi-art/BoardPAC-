package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.meeting.*;
import com.portSrilanka.board_admin_backend.entity.*;
import com.portSrilanka.board_admin_backend.enums.MeetingStatus;
import com.portSrilanka.board_admin_backend.enums.ParticipantStatus;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class MeetingService {

    private final MeetingRepository meetingRepository;
    private final CategoryRepository categoryRepository;
    private final SubcategoryRepository subcategoryRepository;
    private final UserRepository userRepository;
    private final MeetingParticipantRepository meetingParticipantRepository;
    private final MeetingNoteRepository meetingNoteRepository;
    private final UserSubcategoryAccessRepository accessRepository;
    private final AuditService auditService;

    public MeetingResponse create(MeetingRequest request) {
        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new ResourceNotFoundException("Category not found"));
        Subcategory subcategory = subcategoryRepository.findById(request.getSubcategoryId())
                .orElseThrow(() -> new ResourceNotFoundException("Subcategory not found"));
        User createdBy = userRepository.findById(request.getCreatedByUserId())
                .orElseThrow(() -> new ResourceNotFoundException("Creator not found"));

        Meeting meeting = Meeting.builder()
                .title(request.getTitle())
                .type(request.getType())
                .status(MeetingStatus.DRAFT)
                .meetingDateTime(request.getMeetingDateTime())
                .targetDateTime(request.getTargetDateTime())
                .location(request.getLocation())
                .description(request.getDescription())
                .category(category)
                .subcategory(subcategory)
                .createdBy(createdBy)
                .build();

        meeting = meetingRepository.save(meeting);

        auditService.logInfo("MEETING", "CREATE_MEETING", createdBy.getUsername(),
                "Meeting created: " + meeting.getTitle(), "WEB");

        return mapMeeting(meeting);
    }

    public List<MeetingResponse> getAll() {
        return meetingRepository.findAll().stream().map(this::mapMeeting).toList();
    }

    public List<MeetingResponse> getBySubcategory(Long subcategoryId) {
        return meetingRepository.findBySubcategoryId(subcategoryId).stream().map(this::mapMeeting).toList();
    }

    public MeetingResponse openMeeting(Long meetingId) {
        Meeting meeting = findMeeting(meetingId);
        meeting.setStatus(MeetingStatus.OPEN);
        meeting = meetingRepository.save(meeting);

        auditService.logInfo("MEETING", "OPEN_MEETING", "SYSTEM",
                "Meeting opened: " + meeting.getTitle(), "WEB");

        return mapMeeting(meeting);
    }

    public MeetingResponse closeMeeting(Long meetingId) {
        Meeting meeting = findMeeting(meetingId);
        meeting.setStatus(MeetingStatus.CLOSED);
        meeting = meetingRepository.save(meeting);

        auditService.logInfo("MEETING", "CLOSE_MEETING", "SYSTEM",
                "Meeting closed: " + meeting.getTitle(), "WEB");

        return mapMeeting(meeting);
    }

    public MeetingParticipantResponse addParticipant(MeetingParticipantRequest request) {
        Meeting meeting = findMeeting(request.getMeetingId());
        User user = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        accessRepository.findByUserId(user.getId()).stream()
                .filter(a -> a.getSubcategory().getId().equals(meeting.getSubcategory().getId()))
                .findFirst()
                .orElseThrow(() -> new ResourceNotFoundException("User has no privilege for this subcategory"));

        MeetingParticipant participant = MeetingParticipant.builder()
                .meeting(meeting)
                .user(user)
                .participantStatus(ParticipantStatus.PENDING)
                .displaySequence(request.getDisplaySequence())
                .build();

        participant = meetingParticipantRepository.save(participant);

        return mapParticipant(participant);
    }

    public List<MeetingParticipantResponse> getParticipants(Long meetingId) {
        return meetingParticipantRepository.findByMeetingIdOrderByDisplaySequenceAsc(meetingId)
                .stream().map(this::mapParticipant).toList();
    }

    public MeetingParticipantResponse updateParticipantStatus(ParticipantStatusUpdateRequest request) {
        MeetingParticipant participant = meetingParticipantRepository
                .findByMeetingIdAndUserId(request.getMeetingId(), request.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("Participant not found"));

        participant.setParticipantStatus(request.getParticipantStatus());
        participant.setStatusReason(request.getStatusReason());
        participant = meetingParticipantRepository.save(participant);

        auditService.logInfo("MEETING", "UPDATE_PARTICIPANT_STATUS",
                participant.getUser().getUsername(),
                "Status=" + request.getParticipantStatus(), "DEVICE");

        return mapParticipant(participant);
    }

    public String addMeetingNote(MeetingNoteRequest request) {
        Meeting meeting = findMeeting(request.getMeetingId());
        User user = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        MeetingNote note = MeetingNote.builder()
                .meeting(meeting)
                .user(user)
                .noteText(request.getNoteText())
                .build();

        meetingNoteRepository.save(note);

        auditService.logInfo("MEETING", "ADD_MEETING_NOTE",
                user.getUsername(), "Added note to meeting " + meeting.getTitle(), "DEVICE");

        return "Meeting note added successfully";
    }

    private Meeting findMeeting(Long id) {
        return meetingRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Meeting not found"));
    }

    private MeetingResponse mapMeeting(Meeting meeting) {
        return MeetingResponse.builder()
                .id(meeting.getId())
                .title(meeting.getTitle())
                .type(meeting.getType())
                .status(meeting.getStatus())
                .meetingDateTime(meeting.getMeetingDateTime())
                .targetDateTime(meeting.getTargetDateTime())
                .location(meeting.getLocation())
                .description(meeting.getDescription())
                .categoryName(meeting.getCategory().getName())
                .subcategoryName(meeting.getSubcategory().getName())
                .build();
    }

    private MeetingParticipantResponse mapParticipant(MeetingParticipant participant) {
        return MeetingParticipantResponse.builder()
                .id(participant.getId())
                .userId(participant.getUser().getId())
                .username(participant.getUser().getUsername())
                .participantStatus(participant.getParticipantStatus())
                .statusReason(participant.getStatusReason())
                .displaySequence(participant.getDisplaySequence())
                .build();
    }
}

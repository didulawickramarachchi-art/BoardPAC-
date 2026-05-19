package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.meeting.*;
import com.portSrilanka.board_admin_backend.entity.*;
import com.portSrilanka.board_admin_backend.enums.MeetingStatus;
import com.portSrilanka.board_admin_backend.enums.ParticipantStatus;
import com.portSrilanka.board_admin_backend.enums.UserStatus;
import com.portSrilanka.board_admin_backend.exception.BadRequestException;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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

    @Transactional
    public MeetingResponse create(MeetingRequest request, String username) {
        validateMeetingRequest(request);

        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new ResourceNotFoundException("Category not found"));

        Subcategory subcategory = subcategoryRepository.findById(request.getSubcategoryId())
                .orElseThrow(() -> new ResourceNotFoundException("Subcategory not found"));

        User createdBy = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("Creator not found"));

        if (createdBy.getStatus() != UserStatus.ACTIVE) {
            throw new BadRequestException("Inactive user cannot create meetings");
        }

        Meeting meeting = Meeting.builder()
                .title(request.getTitle().trim())
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

        auditService.logInfo(
                "MEETING",
                "CREATE_MEETING",
                createdBy.getUsername(),
                "Meeting created: " + meeting.getTitle(),
                "WEB"
        );

        return mapMeeting(meeting);
    }

    public List<MeetingResponse> getAll() {
        return meetingRepository.findAll()
                .stream()
                .map(this::mapMeeting)
                .toList();
    }

    public List<MeetingResponse> getBySubcategory(Long subcategoryId) {
        if (subcategoryId == null) {
            throw new BadRequestException("Subcategory id is required");
        }

        return meetingRepository.findBySubcategoryId(subcategoryId)
                .stream()
                .map(this::mapMeeting)
                .toList();
    }

    @Transactional
    public MeetingResponse openMeeting(Long meetingId) {
        Meeting meeting = findMeeting(meetingId);

        if (meeting.getStatus() != MeetingStatus.DRAFT) {
            throw new BadRequestException("Only draft meetings can be opened");
        }

        meeting.setStatus(MeetingStatus.OPEN);
        meeting = meetingRepository.save(meeting);

        auditService.logInfo(
                "MEETING",
                "OPEN_MEETING",
                "SYSTEM",
                "Meeting opened: " + meeting.getTitle(),
                "WEB"
        );

        return mapMeeting(meeting);
    }

    @Transactional
    public MeetingResponse closeMeeting(Long meetingId) {
        Meeting meeting = findMeeting(meetingId);

        if (meeting.getStatus() != MeetingStatus.OPEN) {
            throw new BadRequestException("Only open meetings can be closed");
        }

        meeting.setStatus(MeetingStatus.CLOSED);
        meeting = meetingRepository.save(meeting);

        auditService.logInfo(
                "MEETING",
                "CLOSE_MEETING",
                "SYSTEM",
                "Meeting closed: " + meeting.getTitle(),
                "WEB"
        );

        return mapMeeting(meeting);
    }

    @Transactional
    public MeetingParticipantResponse addParticipant(MeetingParticipantRequest request) {
        if (request.getMeetingId() == null) {
            throw new BadRequestException("Meeting id is required");
        }

        if (request.getUserId() == null) {
            throw new BadRequestException("User id is required");
        }

        Meeting meeting = findMeeting(request.getMeetingId());

        if (meeting.getStatus() == MeetingStatus.CLOSED) {
            throw new BadRequestException("Cannot add participants to a closed meeting");
        }

        User user = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new BadRequestException("Inactive user cannot be added as participant");
        }

        if (meetingParticipantRepository
                .findByMeetingIdAndUserId(request.getMeetingId(), request.getUserId())
                .isPresent()) {
            throw new BadRequestException("User already added to this meeting");
        }

        boolean hasAccess = accessRepository.findByUserId(user.getId())
                .stream()
                .anyMatch(access -> access.getSubcategory()
                        .getId()
                        .equals(meeting.getSubcategory().getId()));

        if (!hasAccess) {
            throw new BadRequestException("User has no privilege for this subcategory");
        }

        MeetingParticipant participant = MeetingParticipant.builder()
                .meeting(meeting)
                .user(user)
                .participantStatus(ParticipantStatus.PENDING)
                .displaySequence(request.getDisplaySequence())
                .build();

        participant = meetingParticipantRepository.save(participant);

        auditService.logInfo(
                "MEETING",
                "ADD_PARTICIPANT",
                user.getUsername(),
                "Added to meeting: " + meeting.getTitle(),
                "WEB"
        );

        return mapParticipant(participant);
    }

    public List<MeetingParticipantResponse> getParticipants(Long meetingId) {
        if (meetingId == null) {
            throw new BadRequestException("Meeting id is required");
        }

        findMeeting(meetingId);

        return meetingParticipantRepository.findByMeetingIdOrderByDisplaySequenceAsc(meetingId)
                .stream()
                .map(this::mapParticipant)
                .toList();
    }

    @Transactional
    public MeetingParticipantResponse updateParticipantStatus(ParticipantStatusUpdateRequest request) {
        if (request.getMeetingId() == null) {
            throw new BadRequestException("Meeting id is required");
        }

        if (request.getUserId() == null) {
            throw new BadRequestException("User id is required");
        }

        if (request.getParticipantStatus() == null) {
            throw new BadRequestException("Participant status is required");
        }

        Meeting meeting = findMeeting(request.getMeetingId());

        if (meeting.getStatus() == MeetingStatus.CLOSED) {
            throw new BadRequestException("Cannot update participant status for a closed meeting");
        }

        MeetingParticipant participant = meetingParticipantRepository
                .findByMeetingIdAndUserId(request.getMeetingId(), request.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("Participant not found"));

        participant.setParticipantStatus(request.getParticipantStatus());
        participant.setStatusReason(request.getStatusReason());
        participant = meetingParticipantRepository.save(participant);

        auditService.logInfo(
                "MEETING",
                "UPDATE_PARTICIPANT_STATUS",
                participant.getUser().getUsername(),
                "Status=" + request.getParticipantStatus(),
                "DEVICE"
        );

        return mapParticipant(participant);
    }

    @Transactional
    public String addMeetingNote(MeetingNoteRequest request) {
        if (request.getMeetingId() == null) {
            throw new BadRequestException("Meeting id is required");
        }

        if (request.getUserId() == null) {
            throw new BadRequestException("User id is required");
        }

        if (request.getNoteText() == null || request.getNoteText().isBlank()) {
            throw new BadRequestException("Meeting note is required");
        }

        Meeting meeting = findMeeting(request.getMeetingId());

        if (meeting.getStatus() == MeetingStatus.CLOSED) {
            throw new BadRequestException("Cannot add notes to a closed meeting");
        }

        User user = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new BadRequestException("Inactive user cannot add meeting notes");
        }

        boolean hasAccess = accessRepository.findByUserId(user.getId())
                .stream()
                .anyMatch(access -> access.getSubcategory()
                        .getId()
                        .equals(meeting.getSubcategory().getId()));

        if (!hasAccess) {
            throw new BadRequestException("User has no privilege to add notes for this meeting");
        }

        MeetingNote note = MeetingNote.builder()
                .meeting(meeting)
                .user(user)
                .noteText(request.getNoteText().trim())
                .build();

        meetingNoteRepository.save(note);

        auditService.logInfo(
                "MEETING",
                "ADD_MEETING_NOTE",
                user.getUsername(),
                "Added note to meeting " + meeting.getTitle(),
                "DEVICE"
        );

        return "Meeting note added successfully";
    }

    private Meeting findMeeting(Long id) {
        if (id == null) {
            throw new BadRequestException("Meeting id is required");
        }

        return meetingRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Meeting not found"));
    }

    private void validateMeetingRequest(MeetingRequest request) {
        if (request.getTitle() == null || request.getTitle().isBlank()) {
            throw new BadRequestException("Meeting title is required");
        }

        if (request.getType() == null) {
            throw new BadRequestException("Meeting type is required");
        }

        if (request.getMeetingDateTime() == null) {
            throw new BadRequestException("Meeting date time is required");
        }

        if (request.getCategoryId() == null) {
            throw new BadRequestException("Category id is required");
        }

        if (request.getSubcategoryId() == null) {
            throw new BadRequestException("Subcategory id is required");
        }

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
                .categoryName(meeting.getCategory() != null ? meeting.getCategory().getName() : null)
                .subcategoryName(meeting.getSubcategory() != null ? meeting.getSubcategory().getName() : null)
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

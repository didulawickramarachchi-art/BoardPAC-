package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.meeting.*;
import com.portSrilanka.board_admin_backend.entity.*;
import com.portSrilanka.board_admin_backend.exception.*;
import com.portSrilanka.board_admin_backend.repository.*;
import com.portSrilanka.board_admin_backend.security.PermissionService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.List;

@Service @RequiredArgsConstructor
public class MeetingWorkspaceService {
    private final MeetingRepository meetingRepository;
    private final MeetingNoteRepository noteRepository;
    private final MeetingMinutesRepository minutesRepository;
    private final UserRepository userRepository;
    private final PermissionService permissionService;

    public List<PrivateMeetingNoteResponse> notes(Long meetingId, String username) {
        User user = user(username);
        meetingForUser(meetingId, user);
        return noteRepository.findByMeetingIdAndUserId(meetingId, user.getId())
                .stream().map(this::mapNote).toList();
    }

    @Transactional
    public PrivateMeetingNoteResponse addNote(Long meetingId, String text, String username) {
        if (text == null || text.isBlank()) throw new BadRequestException("Note is required");
        User user = user(username);
        Meeting meeting = meetingForUser(meetingId, user);
        return mapNote(noteRepository.save(MeetingNote.builder()
                .meeting(meeting).user(user).noteText(text.trim()).build()));
    }

    @Transactional
    public PrivateMeetingNoteResponse updateNote(Long noteId, String text, String username) {
        if (text == null || text.isBlank()) throw new BadRequestException("Note is required");
        User user = user(username);
        MeetingNote note = noteRepository.findById(noteId)
                .orElseThrow(() -> new ResourceNotFoundException("Note not found"));
        if (!note.getUser().getId().equals(user.getId())) throw new AccessDeniedException("Private note owner only");
        note.setNoteText(text.trim());
        return mapNote(noteRepository.save(note));
    }

    @Transactional
    public void deleteNote(Long noteId, String username) {
        User user = user(username);
        MeetingNote note = noteRepository.findById(noteId)
                .orElseThrow(() -> new ResourceNotFoundException("Note not found"));
        if (!note.getUser().getId().equals(user.getId())) throw new AccessDeniedException("Private note owner only");
        noteRepository.delete(note);
    }

    public List<MeetingMinutesResponse> minutes(Long meetingId, String username, boolean secretary) {
        User user = user(username);
        meetingForUser(meetingId, user);
        return minutesRepository.findByMeetingIdOrderByVersionNumberDesc(meetingId)
                .stream().filter(item -> secretary || item.getStatus().equals("PUBLISHED"))
                .map(this::mapMinutes).toList();
    }

    @Transactional
    public MeetingMinutesResponse createMinutes(Long meetingId, String content, String username) {
        if (content == null || content.isBlank()) throw new BadRequestException("Minutes content is required");
        User user = user(username);
        Meeting meeting = meetingRepository.findById(meetingId)
                .orElseThrow(() -> new ResourceNotFoundException("Meeting not found"));
        int version = minutesRepository.findTopByMeetingIdOrderByVersionNumberDesc(meetingId)
                .map(item -> item.getVersionNumber() + 1).orElse(1);
        return mapMinutes(minutesRepository.save(MeetingMinutes.builder()
                .meeting(meeting).versionNumber(version).content(content.trim())
                .status("DRAFT").createdBy(user).build()));
    }

    @Transactional
    public MeetingMinutesResponse transition(Long id, String action, String comment, String username) {
        MeetingMinutes minutes = minutesRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Minutes not found"));
        User reviewer = user(username);
        String next = switch (action.toUpperCase()) {
            case "SUBMIT" -> "IN_REVIEW";
            case "APPROVE" -> "APPROVED";
            case "REJECT" -> "REJECTED";
            case "PUBLISH" -> "PUBLISHED";
            default -> throw new BadRequestException("Unsupported minutes action");
        };
        boolean allowed = switch (next) {
            case "IN_REVIEW" -> minutes.getStatus().equals("DRAFT");
            case "APPROVED", "REJECTED" -> minutes.getStatus().equals("IN_REVIEW");
            case "PUBLISHED" -> minutes.getStatus().equals("APPROVED");
            default -> false;
        };
        if (!allowed) throw new BadRequestException(
                "Cannot change minutes from " + minutes.getStatus() + " to " + next);
        if (next.equals("REJECTED") && (comment == null || comment.isBlank()))
            throw new BadRequestException("A rejection comment is required");
        minutes.setStatus(next);
        minutes.setReviewedBy(reviewer);
        minutes.setReviewComment(comment);
        if (next.equals("PUBLISHED")) minutes.setPublishedAt(LocalDateTime.now());
        return mapMinutes(minutesRepository.save(minutes));
    }

    private Meeting meetingForUser(Long meetingId, User user) {
        Meeting meeting = meetingRepository.findById(meetingId)
                .orElseThrow(() -> new ResourceNotFoundException("Meeting not found"));
        boolean secretary = user.getRoles().stream().anyMatch(role ->
                role.getName().authorityName().equals("SECRETARY"));
        if (!secretary && !permissionService.hasSubcategoryAccess(
                user.getId(), meeting.getSubcategory().getId()))
            throw new AccessDeniedException("User has no access to this meeting");
        return meeting;
    }

    private User user(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private PrivateMeetingNoteResponse mapNote(MeetingNote note) {
        return PrivateMeetingNoteResponse.builder().id(note.getId())
                .meetingId(note.getMeeting().getId()).noteText(note.getNoteText())
                .createdAt(note.getCreatedAt()).updatedAt(note.getUpdatedAt()).build();
    }

    private MeetingMinutesResponse mapMinutes(MeetingMinutes item) {
        return MeetingMinutesResponse.builder().id(item.getId())
                .meetingId(item.getMeeting().getId()).versionNumber(item.getVersionNumber())
                .content(item.getContent()).status(item.getStatus())
                .createdBy(item.getCreatedBy().getUsername())
                .reviewedBy(item.getReviewedBy() == null ? null : item.getReviewedBy().getUsername())
                .reviewComment(item.getReviewComment()).publishedAt(item.getPublishedAt())
                .createdAt(item.getCreatedAt()).updatedAt(item.getUpdatedAt()).build();
    }
}

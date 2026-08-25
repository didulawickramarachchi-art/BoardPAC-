package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.entity.Meeting;
import com.portSrilanka.board_admin_backend.entity.Paper;
import com.portSrilanka.board_admin_backend.repository.MeetingRepository;
import com.portSrilanka.board_admin_backend.repository.PaperRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PaperStoragePathService {
    private final MeetingRepository meetingRepository;
    private final PaperRepository paperRepository;

    public String buildPath(Long meetingId, Long paperId, String originalFileName) {
        Meeting meeting = resolveMeeting(meetingId, paperId);
        String category = preferredName(meeting.getCategory().getDisplayName(),
                meeting.getCategory().getName(), "Uncategorized");
        String subcategory = preferredName(meeting.getSubcategory().getDisplayName(),
                meeting.getSubcategory().getName(), "General");

        return String.join("/", sanitizeSegment(category), sanitizeSegment(subcategory),
                sanitizeSegment(meeting.getTitle()), "BoardPaper",
                UUID.randomUUID() + "_" + sanitizeFileName(originalFileName));
    }

    private Meeting resolveMeeting(Long meetingId, Long paperId) {
        if (meetingId != null) {
            return meetingRepository.findById(meetingId)
                    .orElseThrow(() -> new IllegalArgumentException("Meeting not found: " + meetingId));
        }
        if (paperId != null) {
            Paper paper = paperRepository.findById(paperId)
                    .orElseThrow(() -> new IllegalArgumentException("Paper not found: " + paperId));
            if (paper.getMeeting() == null) {
                throw new IllegalArgumentException("Paper is not linked to a meeting: " + paperId);
            }
            return paper.getMeeting();
        }
        throw new IllegalArgumentException("meetingId or paperId is required for BoardPaper storage");
    }

    private static String preferredName(String displayName, String name, String fallback) {
        if (displayName != null && !displayName.isBlank()) return displayName;
        if (name != null && !name.isBlank()) return name;
        return fallback;
    }

    static String sanitizeSegment(String value) {
        if (value == null || value.isBlank()) return "Unnamed";
        String sanitized = value.trim().replaceAll("[\\\\/]", "-")
                .replaceAll("[^a-zA-Z0-9._() -]", "_")
                .replaceAll("\\s+", "_").replaceAll("\\.{2,}", ".")
                .replaceAll("^[.]+|[.]+$", "");
        if (sanitized.isBlank()) return "Unnamed";
        return sanitized.length() <= 100 ? sanitized : sanitized.substring(0, 100);
    }

    static String sanitizeFileName(String value) {
        String fileName = value == null ? "file" : value.replace('\\', '/');
        fileName = fileName.substring(fileName.lastIndexOf('/') + 1);
        return sanitizeSegment(fileName);
    }
}

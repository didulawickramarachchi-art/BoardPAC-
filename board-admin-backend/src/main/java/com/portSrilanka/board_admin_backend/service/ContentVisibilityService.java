package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.entity.AppSetting;
import com.portSrilanka.board_admin_backend.entity.Meeting;
import com.portSrilanka.board_admin_backend.entity.Paper;
import com.portSrilanka.board_admin_backend.enums.SettingGroup;
import com.portSrilanka.board_admin_backend.repository.AppSettingRepository;
import com.portSrilanka.board_admin_backend.repository.MeetingRepository;
import com.portSrilanka.board_admin_backend.repository.PaperRepository;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

@Service
public class ContentVisibilityService {
    public static final String KEY = "CONTENT_HIDE_PERIOD";
    private static final ZoneId BOARD_ZONE = ZoneId.of("Asia/Colombo");
    private final AppSettingRepository settings;
    private final MeetingRepository meetings;
    private final PaperRepository papers;

    public ContentVisibilityService(AppSettingRepository settings, MeetingRepository meetings, PaperRepository papers) {
        this.settings = settings;
        this.meetings = meetings;
        this.papers = papers;
    }

    public record Period(LocalDate startDate, LocalDate endDate) {}

    public Period current() {
        return settings.findBySettingKey(KEY).map(setting -> {
            String[] parts = setting.getSettingValue().split("\\|", -1);
            if (parts.length != 2) return new Period(null, null);
            try {
                // Preserve dates selected with the original timed-hide form.
                if (parts[0].contains("T")) return new Period(
                        Instant.parse(parts[0]).atZone(BOARD_ZONE).toLocalDate(),
                        Instant.parse(parts[1]).atZone(BOARD_ZONE).toLocalDate());
                return new Period(LocalDate.parse(parts[0]), LocalDate.parse(parts[1]));
            } catch (RuntimeException ex) {
                return new Period(null, null);
            }
        }).orElse(new Period(null, null));
    }

    public Period schedule(LocalDate startDate, LocalDate endDate) {
        if (startDate == null || endDate == null || startDate.isAfter(endDate)) {
            throw new IllegalArgumentException("Start date must be on or before end date");
        }
        AppSetting setting = settings.findBySettingKey(KEY).orElseGet(AppSetting::new);
        setting.setSettingKey(KEY);
        setting.setSettingGroup(SettingGroup.GENERAL);
        setting.setSettingValue(startDate + "|" + endDate);
        setting.setDescription("Hide meetings dated in this range and their papers from non-admin users");
        settings.save(setting);
        return new Period(startDate, endDate);
    }

    public boolean isHidden(LocalDateTime meetingDateTime) {
        return isHidden(meetingDateTime, current());
    }

    public boolean isHidden(LocalDateTime meetingDateTime, Period period) {
        if (meetingDateTime == null || isAdmin()) return false;
        if (period.startDate() == null || period.endDate() == null) return false;
        LocalDate date = meetingDateTime.toLocalDate();
        return !date.isBefore(period.startDate()) && !date.isAfter(period.endDate());
    }

    public boolean isHidden(Meeting meeting) {
        return meeting != null && isHidden(meeting.getMeetingDateTime());
    }

    public boolean isHidden(Meeting meeting, Period period) {
        return meeting != null && isHidden(meeting.getMeetingDateTime(), period);
    }

    public boolean isHidden(Paper paper) {
        return paper != null && isHidden(paper.getMeeting());
    }

    public boolean isHidden(Paper paper, Period period) {
        return paper != null && isHidden(paper.getMeeting(), period);
    }

    public boolean isHiddenMeeting(Long id) {
        if (id == null) return false;
        return isHiddenMeeting(id, current());
    }

    public boolean isHiddenMeeting(Long id, Period period) {
        return id != null && !isAdmin() && meetings.findById(id)
                .map(meeting -> isHidden(meeting, period)).orElse(false);
    }

    public boolean isHiddenPaper(Long id) {
        if (id == null) return false;
        return isHiddenPaper(id, current());
    }

    public boolean isHiddenPaper(Long id, Period period) {
        return id != null && !isAdmin() && papers.findById(id)
                .map(paper -> isHidden(paper, period)).orElse(false);
    }

    public void clear() {
        settings.findBySettingKey(KEY).ifPresent(settings::delete);
    }

    private boolean isAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth != null && auth.getAuthorities().stream()
                .anyMatch(authority -> "ROLE_ADMIN".equals(authority.getAuthority()));
    }
}

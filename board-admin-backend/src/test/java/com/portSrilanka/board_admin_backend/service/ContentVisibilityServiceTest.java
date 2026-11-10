package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.entity.AppSetting;
import com.portSrilanka.board_admin_backend.entity.Meeting;
import com.portSrilanka.board_admin_backend.entity.Paper;
import com.portSrilanka.board_admin_backend.repository.AppSettingRepository;
import com.portSrilanka.board_admin_backend.repository.MeetingRepository;
import com.portSrilanka.board_admin_backend.repository.PaperRepository;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ContentVisibilityServiceTest {
    private final AppSettingRepository settings = mock(AppSettingRepository.class);
    private final MeetingRepository meetings = mock(MeetingRepository.class);
    private final PaperRepository papers = mock(PaperRepository.class);
    private final ContentVisibilityService service = new ContentVisibilityService(settings, meetings, papers);

    @Test
    void hidesOnlyMeetingDatesWithinInclusiveRangeAndTheirPapers() {
        AppSetting setting = new AppSetting();
        setting.setSettingValue("2018-01-10|2026-05-10");
        when(settings.findBySettingKey(ContentVisibilityService.KEY)).thenReturn(Optional.of(setting));
        Meeting old = new Meeting(); old.setMeetingDateTime(LocalDateTime.parse("2020-06-01T12:00:00"));
        Meeting current = new Meeting(); current.setMeetingDateTime(LocalDateTime.parse("2026-11-10T12:00:00"));
        Paper oldPaper = new Paper(); oldPaper.setMeeting(old);

        assertTrue(service.isHidden(old));
        assertTrue(service.isHidden(oldPaper));
        assertTrue(service.isHidden(LocalDateTime.parse("2026-05-10T23:59:59")));
        assertFalse(service.isHidden(current));
        assertFalse(service.isHidden(LocalDateTime.parse("2018-01-09T23:59:59")));
    }

    @Test
    void convertsPreviouslySavedTimedPeriodToBoardDates() {
        AppSetting setting = new AppSetting();
        setting.setSettingValue("2018-01-10T07:14:00Z|2026-05-10T07:14:00Z");
        when(settings.findBySettingKey(ContentVisibilityService.KEY)).thenReturn(Optional.of(setting));
        assertEquals(new ContentVisibilityService.Period(
                LocalDate.parse("2018-01-10"), LocalDate.parse("2026-05-10")), service.current());
    }

    @Test
    void rejectsReversedDates() {
        assertThrows(IllegalArgumentException.class, () -> service.schedule(
                LocalDate.parse("2026-05-10"), LocalDate.parse("2018-01-10")));
        verify(settings, never()).save(any());
    }
}

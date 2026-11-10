package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.entity.AppSetting;
import com.portSrilanka.board_admin_backend.repository.AppSettingRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ContentVisibilityServiceTest {
    @Test
    void periodStartsInclusivelyAndEndsExclusively() {
        AppSettingRepository repository = mock(AppSettingRepository.class);
        AppSetting setting = new AppSetting();
        setting.setSettingValue("2026-11-10T09:00:00Z|2026-11-10T10:00:00Z");
        when(repository.findBySettingKey(ContentVisibilityService.KEY)).thenReturn(Optional.of(setting));

        assertFalse(at(repository, "2026-11-10T08:59:59Z").current().active());
        assertTrue(at(repository, "2026-11-10T09:00:00Z").current().active());
        assertTrue(at(repository, "2026-11-10T09:59:59Z").current().active());
        assertFalse(at(repository, "2026-11-10T10:00:00Z").current().active());
    }

    @Test
    void rejectsInvalidPeriod() {
        AppSettingRepository repository = mock(AppSettingRepository.class);
        var service = at(repository, "2026-11-10T09:00:00Z");
        Instant time = Instant.parse("2026-11-10T09:00:00Z");
        assertThrows(IllegalArgumentException.class, () -> service.schedule(time, time));
        verify(repository, never()).save(any());
    }

    private ContentVisibilityService at(AppSettingRepository repository, String time) {
        return new ContentVisibilityService(repository, Clock.fixed(Instant.parse(time), ZoneOffset.UTC));
    }
}

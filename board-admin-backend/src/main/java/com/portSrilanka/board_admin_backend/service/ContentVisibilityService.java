package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.entity.AppSetting;
import com.portSrilanka.board_admin_backend.enums.SettingGroup;
import com.portSrilanka.board_admin_backend.repository.AppSettingRepository;
import java.time.Clock;
import java.time.Instant;
import org.springframework.stereotype.Service;

@Service
public class ContentVisibilityService {
    public static final String KEY = "CONTENT_HIDE_PERIOD";
    private final AppSettingRepository settings;
    private final Clock clock;

    public ContentVisibilityService(AppSettingRepository settings) {
        this(settings, Clock.systemUTC());
    }

    ContentVisibilityService(AppSettingRepository settings, Clock clock) {
        this.settings = settings;
        this.clock = clock;
    }

    public record Period(Instant startAt, Instant endAt, boolean active) {}

    public Period current() {
        return settings.findBySettingKey(KEY).map(setting -> {
            String[] parts = setting.getSettingValue().split("\\|", -1);
            if (parts.length != 2) return new Period(null, null, false);
            try {
                Instant start = Instant.parse(parts[0]);
                Instant end = Instant.parse(parts[1]);
                Instant now = clock.instant();
                return new Period(start, end, !now.isBefore(start) && now.isBefore(end));
            } catch (RuntimeException ex) {
                return new Period(null, null, false);
            }
        }).orElse(new Period(null, null, false));
    }

    public Period schedule(Instant startAt, Instant endAt) {
        if (startAt == null || endAt == null || !startAt.isBefore(endAt)) {
            throw new IllegalArgumentException("Start time must be before end time");
        }
        AppSetting setting = settings.findBySettingKey(KEY).orElseGet(AppSetting::new);
        setting.setSettingKey(KEY);
        setting.setSettingGroup(SettingGroup.GENERAL);
        setting.setSettingValue(startAt + "|" + endAt);
        setting.setDescription("Hide meetings and papers from all non-admin users during this period");
        settings.save(setting);
        return current();
    }

    public void clear() {
        settings.findBySettingKey(KEY).ifPresent(settings::delete);
    }
}

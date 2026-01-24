package com.example.backend_api.service;

import com.example.backend_api.model.Restaurant;
import org.springframework.stereotype.Service;

import java.time.*;

@Service
public class TimeWindowService {
    private static final ZoneId ZONE = ZoneId.of("Europe/Chisinau");

    public record WorkWindow(OffsetDateTime start, OffsetDateTime end) {}

    public WorkWindow windowForDate(Restaurant r, LocalDate date) {
        OffsetDateTime start = date.atTime(r.getOpenTime()).atZone(ZONE).toOffsetDateTime();

        LocalDate endDate = r.isCrossesMidnight() ? date.plusDays(1) : date;
        OffsetDateTime end = endDate.atTime(r.getCloseTime()).atZone(ZONE).toOffsetDateTime();

        return new WorkWindow(start, end);
    }
}

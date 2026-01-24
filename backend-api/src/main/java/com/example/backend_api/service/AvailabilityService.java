package com.example.backend_api.service;

import com.example.backend_api.model.DiningTable;
import com.example.backend_api.model.Restaurant;
import com.example.backend_api.model.ReservationStatus;
import com.example.backend_api.repo.DiningTableRepository;
import com.example.backend_api.repo.RestaurantRepository;
import com.example.backend_api.repo.ReservationRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

@Service
public class AvailabilityService {
    private static final Set<Integer> ALLOWED = Set.of(60, 90, 120, 150);

    private final RestaurantRepository restaurants;
    private final DiningTableRepository tables;
    private final ReservationRepository reservations;
    private final TimeWindowService timeWindow;

    public AvailabilityService(RestaurantRepository restaurants,
                               DiningTableRepository tables,
                               ReservationRepository reservations,
                               TimeWindowService timeWindow) {
        this.restaurants = restaurants;
        this.tables = tables;
        this.reservations = reservations;
        this.timeWindow = timeWindow;
    }

    public List<String> getSlots(int restaurantId, LocalDate date, int persons, int durationMin) {
        if (!ALLOWED.contains(durationMin)) {
            throw new RuntimeException("Duration must be 60/90/120/150");
        }

        Restaurant r = restaurants.findById(restaurantId)
                .orElseThrow(() -> new RuntimeException("Restaurant not found"));

        var window = timeWindow.windowForDate(r, date);

        List<DiningTable> candidateTables = tables.findCandidates(restaurantId, persons);
        if (candidateTables.isEmpty()) {
            return List.of();
        }

        // Statusurile care blochează masa (nu permite suprapunere)
        List<ReservationStatus> blockingStatuses =
                List.of(ReservationStatus.PENDING, ReservationStatus.CONFIRMED);

        List<String> result = new ArrayList<>();
        OffsetDateTime slot = roundUpTo15(window.start());

        while (true) {
            OffsetDateTime end = slot.plusMinutes(durationMin);
            if (end.isAfter(window.end())) break;

            boolean existsFreeTable = false;
            for (DiningTable t : candidateTables) {
                // IMPORTANT: repo-ul trebuie să aibă semnătura cu statuses
                if (!reservations.existsOverlap(t.getId(), blockingStatuses, slot, end)) {
    existsFreeTable = true;
    break;
}

            }

            if (existsFreeTable) result.add(slot.toString());
            slot = slot.plusMinutes(15);
        }

        return result;
    }

    private OffsetDateTime roundUpTo15(OffsetDateTime dt) {
        int minute = dt.getMinute();
        int add = (15 - (minute % 15)) % 15;
        return dt.plusMinutes(add).withSecond(0).withNano(0);
    }
}

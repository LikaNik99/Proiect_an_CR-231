package com.example.backend_api.service;

import com.example.backend_api.dto.CreateReservationRequest;
import com.example.backend_api.dto.ReservationDto;
import com.example.backend_api.model.*;
import com.example.backend_api.repo.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.*;
import java.util.List;
import java.util.Set;

@Service
public class ReservationService {

    private static final Set<Integer> ALLOWED = Set.of(60, 90, 120, 150);
    private static final ZoneId ZONE = ZoneId.of("Europe/Chisinau");
    private static final List<ReservationStatus> ACTIVE_STATUSES = List.of(
            ReservationStatus.PENDING,
            ReservationStatus.CONFIRMED
    );

    private final RestaurantRepository restaurants;
    private final DiningTableRepository tables;
    private final ReservationRepository reservations;
    private final UserRepository users;
    private final TimeWindowService timeWindow;

    public ReservationService(RestaurantRepository restaurants,
                              DiningTableRepository tables,
                              ReservationRepository reservations,
                              UserRepository users,
                              TimeWindowService timeWindow) {
        this.restaurants = restaurants;
        this.tables = tables;
        this.reservations = reservations;
        this.users = users;
        this.timeWindow = timeWindow;
    }

    @Transactional
    public ReservationDto create(int customerId, CreateReservationRequest req) {
        if (!ALLOWED.contains(req.durationMin)) {
            throw new RuntimeException("Duration must be 60/90/120/150");
        }

        Restaurant r = restaurants.findById(req.restaurantId)
                .orElseThrow(() -> new RuntimeException("Restaurant not found"));
        User customer = users.findById(customerId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        OffsetDateTime start = req.startDt;
        OffsetDateTime end = start.plusMinutes(req.durationMin);

        LocalDate date = start.atZoneSameInstant(ZONE).toLocalDate();
        var window = timeWindow.windowForDate(r, date);

        if (start.isBefore(window.start()) || end.isAfter(window.end())) {
            throw new RuntimeException("Outside working hours");
        }

        List<DiningTable> candidateTables = tables.findCandidates(r.getId(), req.persons);

        for (DiningTable t : candidateTables) {
            boolean hasOverlap = reservations.existsOverlap(t.getId(), ACTIVE_STATUSES, start, end);
            if (hasOverlap) {
                continue;
            }

            Reservation res = new Reservation();
            res.setRestaurant(r);
            res.setTable(t);
            res.setCustomer(customer);
            res.setStartDt(start);
            res.setEndDt(end);
            res.setPersons(req.persons);
            res.setDurationMin(req.durationMin);
            res.setStatus(ReservationStatus.PENDING);

            Reservation saved = reservations.save(res);
            return new ReservationDto(
                    saved.getId(),
                    saved.getRestaurant().getId(),
                    saved.getRestaurant().getName(),
                    saved.getTable().getId(),
                    saved.getTable().getTableNo(),
                    saved.getStartDt().toString(),
                    saved.getEndDt().toString(),
                    saved.getPersons(),
                    saved.getDurationMin(),
                    saved.getStatus().name(),
                    saved.getCustomer().getFullName(),
                    saved.getCustomer().getEmail()
            );
        }

        throw new RuntimeException("Masa este deja rezervată pentru acest interval orar. Vă rugăm să selectați o altă oră.");
    }

    public List<ReservationDto> myReservations(int customerId) {
        return reservations.findByCustomerIdOrderByStartDtDesc(customerId).stream()
                .map(r -> new ReservationDto(
                        r.getId(),
                        r.getRestaurant().getId(),
                        r.getRestaurant().getName(),
                        r.getTable().getId(),
                        r.getTable().getTableNo(),
                        r.getStartDt().toString(),
                        r.getEndDt().toString(),
                        r.getPersons(),
                        r.getDurationMin(),
                        r.getStatus().name(),
                        r.getCustomer().getFullName(),
                        r.getCustomer().getEmail()
                ))
                .toList();
    }
}

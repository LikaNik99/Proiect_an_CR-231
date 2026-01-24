package com.example.backend_api.service;

import com.example.backend_api.dto.ReservationDto;
import com.example.backend_api.model.Reservation;
import com.example.backend_api.model.ReservationStatus;
import com.example.backend_api.model.User;
import com.example.backend_api.repo.RestaurantAdminRepository;
import com.example.backend_api.repo.ReservationRepository;
import com.example.backend_api.repo.UserRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Set;

@Service
public class AdminService {
    private final RestaurantAdminRepository admins;
    private final ReservationRepository reservations;
    private final UserRepository users;

    public AdminService(RestaurantAdminRepository admins, ReservationRepository reservations, UserRepository users) {
        this.admins = admins; this.reservations = reservations; this.users = users;
    }

    public List<Integer> adminRestaurantIds(int userId) {
        return admins.findByUserId(userId).stream().map(a -> a.getRestaurantId()).toList();
    }

    public List<ReservationDto> reservationsForRestaurant(int adminId, int restaurantId) {
        ensureAccess(adminId, restaurantId);
        return reservations.findByRestaurant(restaurantId).stream().map(this::toDto).toList();
    }

    public ReservationDto updateStatus(int adminId, int restaurantId, int reservationId, String status) {
        ensureAccess(adminId, restaurantId);
        Reservation r = reservations.findById(reservationId).orElseThrow(() -> new RuntimeException("Not found"));

        if (r.getRestaurant().getId() != restaurantId) throw new RuntimeException("Wrong restaurant");

        ReservationStatus st = ReservationStatus.valueOf(status);
        r.setStatus(st);
        reservations.save(r);
        return toDto(r);
    }

    private void ensureAccess(int adminId, int restaurantId) {
        User u = users.findById(adminId).orElseThrow();
        if (u.getRole().name().equals("SUPER_ADMIN")) return;
        Set<Integer> allowed = Set.copyOf(adminRestaurantIds(adminId));
        if (!allowed.contains(restaurantId)) throw new RuntimeException("Forbidden");
    }

    private ReservationDto toDto(Reservation r) {
        return new ReservationDto(
                r.getId(), r.getRestaurant().getId(), r.getRestaurant().getName(), r.getTable().getId(), r.getTable().getTableNo(),
                r.getStartDt().toString(), r.getEndDt().toString(),
                r.getPersons(), r.getDurationMin(), r.getStatus().name(),
                r.getCustomer().getFullName(), r.getCustomer().getEmail()
        );
    }
}

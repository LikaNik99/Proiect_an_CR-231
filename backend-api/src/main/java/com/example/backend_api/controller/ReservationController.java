package com.example.backend_api.controller;

import com.example.backend_api.dto.*;
import com.example.backend_api.service.ReservationService;
import jakarta.validation.Valid;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
public class ReservationController {

    private final ReservationService reservations;

    public ReservationController(ReservationService reservations) { this.reservations = reservations; }

    @PostMapping("/reservations")
    public ReservationDto create(Authentication auth, @RequestBody @Valid CreateReservationRequest req) {
        Integer userId = (Integer) auth.getPrincipal();
        return reservations.create(userId, req);
    }

    @GetMapping("/me/reservations")
    public List<ReservationDto> my(Authentication auth) {
        Integer userId = (Integer) auth.getPrincipal();
        return reservations.myReservations(userId);
    }
}

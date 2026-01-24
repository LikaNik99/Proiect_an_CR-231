package com.example.backend_api.dto;

import jakarta.validation.constraints.*;
import java.time.OffsetDateTime;

public class CreateReservationRequest {
    @Min(1) public int restaurantId;
    @NotNull public OffsetDateTime startDt; // ex: 2026-01-21T19:00:00+02:00
    @Min(1) public int persons;
    @Min(60) public int durationMin;
}

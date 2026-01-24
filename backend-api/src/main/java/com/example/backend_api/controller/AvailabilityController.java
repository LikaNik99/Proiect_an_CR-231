package com.example.backend_api.controller;

import com.example.backend_api.service.AvailabilityService;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/restaurants/{id}/availability")
public class AvailabilityController {
    private final AvailabilityService availability;

    public AvailabilityController(AvailabilityService availability) { this.availability = availability; }

    @GetMapping
    public List<String> slots(@PathVariable("id") int restaurantId,
                              @RequestParam("date") String date,
                              @RequestParam("persons") int persons,
                              @RequestParam("duration") int duration) {
        return availability.getSlots(restaurantId, LocalDate.parse(date), persons, duration);
    }
}

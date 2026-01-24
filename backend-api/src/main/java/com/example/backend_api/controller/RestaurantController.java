package com.example.backend_api.controller;

import com.example.backend_api.dto.RestaurantDto;
import com.example.backend_api.repo.RestaurantRepository;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/restaurants")
public class RestaurantController {
    private final RestaurantRepository restaurants;

    public RestaurantController(RestaurantRepository restaurants) { this.restaurants = restaurants; }

    @GetMapping
    public List<RestaurantDto> all() {
        return restaurants.findAll().stream()
                .map(r -> new RestaurantDto(
                        r.getId(), r.getName(), r.getAddress(),
                        r.getOpenTime().toString(), r.getCloseTime().toString(), r.isCrossesMidnight(),
                        r.getCuisine(), r.getPriceSign(), r.getImageUrl()
                )).toList();
    }

    @GetMapping("/{id}")
    public RestaurantDto one(@PathVariable int id) {
        var r = restaurants.findById(id)
                .orElseThrow(() -> new RuntimeException("Restaurant not found"));

        return new RestaurantDto(
                r.getId(), r.getName(), r.getAddress(),
                r.getOpenTime().toString(), r.getCloseTime().toString(), r.isCrossesMidnight(),
                r.getCuisine(), r.getPriceSign(), r.getImageUrl()
        );
    }
}

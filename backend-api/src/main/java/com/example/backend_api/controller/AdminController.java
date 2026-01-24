package com.example.backend_api.controller;

import com.example.backend_api.dto.ReservationDto;
import com.example.backend_api.repo.UserRepository;
import com.example.backend_api.service.AdminService;
import com.example.backend_api.service.TokenStore;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/admin")
public class AdminController {

    private final AdminService admin;
    private final TokenStore tokenStore;
    private final UserRepository userRepository;

    public AdminController(AdminService admin, TokenStore tokenStore, UserRepository userRepository) {
        this.admin = admin;
        this.tokenStore = tokenStore;
        this.userRepository = userRepository;
    }

    @GetMapping("/restaurants")
    public List<Integer> myRestaurants(Authentication auth) {
        Integer userId = (Integer) auth.getPrincipal();
        return admin.adminRestaurantIds(userId);
    }

    @GetMapping("/debug")
    public Map<String, Object> debug(@RequestHeader(value = "Authorization", required = false) String authHeader) {
        String token = authHeader != null && authHeader.startsWith("Bearer ") 
            ? authHeader.substring(7) 
            : null;
        
        if (token == null) {
            return Map.of("error", "No token provided");
        }
        
        Integer userId = tokenStore.userIdFromToken(token);
        String role = tokenStore.roleFromToken(token);
        List<Integer> adminRestaurants = tokenStore.adminRestaurantIdsFromToken(token);
        
        if (userId == null) {
            return Map.of("error", "Invalid token");
        }
        
        var user = userRepository.findById(userId).orElse(null);
        String dbRole = user != null ? user.getRole().name() : "unknown";
        
        return Map.of(
            "tokenValid", userId != null,
            "userId", userId,
            "tokenRole", role != null ? role : "null",
            "dbRole", dbRole,
            "adminRestaurants", adminRestaurants
        );
    }

    @GetMapping("/reservations")
    public List<ReservationDto> reservations(Authentication auth,
                                             @RequestParam("restaurantId") int restaurantId) {
        Integer userId = (Integer) auth.getPrincipal();
        return admin.reservationsForRestaurant(userId, restaurantId);
    }

    @PatchMapping("/reservations/{id}")
    public ReservationDto update(Authentication auth,
                                 @PathVariable("id") int reservationId,
                                 @RequestParam("restaurantId") int restaurantId,
                                 @RequestParam("status") String status) {
        Integer userId = (Integer) auth.getPrincipal();
        return admin.updateStatus(userId, restaurantId, reservationId, status);
    }
}

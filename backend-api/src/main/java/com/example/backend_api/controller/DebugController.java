package com.example.backend_api.controller;

import com.example.backend_api.model.User;
import com.example.backend_api.repo.UserRepository;
import com.example.backend_api.service.TokenStore;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
public class DebugController {

    private final TokenStore tokenStore;
    private final UserRepository userRepository;

    public DebugController(TokenStore tokenStore, UserRepository userRepository) {
        this.tokenStore = tokenStore;
        this.userRepository = userRepository;
    }

    @GetMapping("/api/debug-token")
    public Map<String, Object> debugToken(@RequestHeader(value = "Authorization", required = false) String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return Map.of("error", "No Bearer token provided");
        }
        
        String token = authHeader.substring(7);
        
        Integer userId = tokenStore.userIdFromToken(token);
        String role = tokenStore.roleFromToken(token);
        List<Integer> adminRestaurants = tokenStore.adminRestaurantIdsFromToken(token);
        
        if (userId == null) {
            return Map.of(
                "error", "Invalid JWT token",
                "tokenLength", token.length(),
                "tokenPreview", token.substring(0, Math.min(20, token.length())) + "..."
            );
        }
        
        User user = userRepository.findById(userId).orElse(null);
        String dbRole = user != null ? user.getRole().name() : "NOT_FOUND";
        
        return Map.of(
            "validJwt", true,
            "userId", userId,
            "tokenRole", role,
            "dbRole", dbRole,
            "adminRestaurants", adminRestaurants
        );
    }

    @GetMapping("/api/test")
    public Map<String, String> test() {
        return Map.of("status", "ok", "message", "API is working");
    }
}

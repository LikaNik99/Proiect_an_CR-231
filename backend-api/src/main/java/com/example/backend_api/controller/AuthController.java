package com.example.backend_api.controller;

import com.example.backend_api.dto.*;
import com.example.backend_api.model.RestaurantAdmin;
import com.example.backend_api.model.User;
import com.example.backend_api.model.UserRole;
import com.example.backend_api.repo.RestaurantAdminRepository;
import com.example.backend_api.repo.UserRepository;
import com.example.backend_api.service.TokenStore;
import jakarta.validation.Valid;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/auth")
public class AuthController {
    private final UserRepository userRepository;
    private final RestaurantAdminRepository restaurantAdminRepository;
    private final TokenStore tokenStore;
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    public AuthController(UserRepository userRepository, RestaurantAdminRepository restaurantAdminRepository, TokenStore tokenStore) {
        this.userRepository = userRepository;
        this.restaurantAdminRepository = restaurantAdminRepository;
        this.tokenStore = tokenStore;
    }

    @PostMapping("/login")
    public LoginResponse login(@RequestBody @Valid LoginRequest req) {
        User u = userRepository.findByEmail(req.email)
                .orElseThrow(() -> new RuntimeException("Invalid credentials"));
        if (!encoder.matches(req.password, u.getPasswordHash())) {
            throw new RuntimeException("Invalid credentials");
        }

        String token = tokenStore.issue(u);

        List<Integer> adminRestaurantIds = switch (u.getRole()) {
            case ADMIN -> restaurantAdminRepository.findByUserId(u.getId())
                    .stream()
                    .map(RestaurantAdmin::getRestaurantId)
                    .toList();
            case SUPER_ADMIN -> List.of(1, 2, 3);
            default -> List.of();
        };

        return new LoginResponse(token, u.getRole().name(), adminRestaurantIds);
    }

    @PostMapping("/register")
    public LoginResponse register(@RequestBody @Valid RegisterRequest req) {
        if (userRepository.findByEmail(req.email).isPresent()) {
            throw new RuntimeException("Email already in use");
        }

        User u = new User();
        u.setFullName(req.fullName);
        u.setEmail(req.email);
        u.setPasswordHash(encoder.encode(req.password));
        u.setRole(UserRole.CUSTOMER);
        userRepository.save(u);

        String token = tokenStore.issue(u);
        return new LoginResponse(token, u.getRole().name(), List.of());
    }

    @PostMapping("/create-admin")
    public Map<String, Object> createAdmin(@RequestBody Map<String, Object> req) {
        String email = (String) req.get("email");
        String password = (String) req.get("password");
        Integer restaurantId = req.containsKey("restaurantId") ? ((Number) req.get("restaurantId")).intValue() : 1;
        
        if (email == null || password == null) {
            return Map.of("error", "Missing email or password");
        }
        
        var existingUser = userRepository.findByEmail(email);
        if (existingUser.isPresent()) {
            return Map.of("error", "Email already exists");
        }
        
        String hashedPassword = encoder.encode(password);
        
        User user = new User();
        user.setFullName("Admin");
        user.setEmail(email);
        user.setPasswordHash(hashedPassword);
        user.setRole(UserRole.ADMIN);
        User savedUser = userRepository.save(user);
        
        RestaurantAdmin adminLink = new RestaurantAdmin();
        adminLink.setUserId(savedUser.getId());
        adminLink.setRestaurantId(restaurantId);
        restaurantAdminRepository.save(adminLink);
        
        return Map.of("success", true, "message", "Admin created", "email", email, "password", password);
    }

    @GetMapping("/test-hash")
    public Map<String, String> testHash(@RequestParam String password) {
        return Map.of("password", password, "hash", encoder.encode(password));
    }
}

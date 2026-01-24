package com.example.backend_api.service;

import com.example.backend_api.dto.LoginResponse;
import com.example.backend_api.model.User;
import com.example.backend_api.model.UserRole;
import com.example.backend_api.repo.RestaurantAdminRepository;
import com.example.backend_api.repo.UserRepository;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AuthService {
    private final UserRepository users;
    private final RestaurantAdminRepository admins;
    private final TokenStore tokenStore;
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    public AuthService(UserRepository users, RestaurantAdminRepository admins, TokenStore tokenStore) {
        this.users = users;
        this.admins = admins;
        this.tokenStore = tokenStore;
    }

    public LoginResponse login(String email, String password) {
        User u = users.findByEmail(email).orElseThrow(() -> new RuntimeException("Invalid credentials"));
        if (!encoder.matches(password, u.getPasswordHash())) throw new RuntimeException("Invalid credentials");

        String token = tokenStore.issue(u);

        List<Integer> adminRestaurantIds = switch (u.getRole()) {
            case ADMIN -> admins.findByUserId(u.getId()).stream().map(a -> a.getRestaurantId()).toList();
            case SUPER_ADMIN -> List.of(1, 2, 3);
            default -> List.of();
        };

        return new LoginResponse(token, u.getRole().name(), adminRestaurantIds);
    }

    public LoginResponse register(String fullName, String email, String password) {
        if (users.findByEmail(email).isPresent()) {
            throw new RuntimeException("Email already in use");
        }

        User u = new User();
        u.setFullName(fullName);
        u.setEmail(email);
        u.setPasswordHash(encoder.encode(password));
        u.setRole(UserRole.CUSTOMER);
        users.save(u);

        String token = tokenStore.issue(u);
        return new LoginResponse(token, u.getRole().name(), List.of());
    }

    public BCryptPasswordEncoder encoder() { return encoder; }
}

package com.example.backend_api.service;

import com.example.backend_api.repo.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class DemoPasswordInitializer implements CommandLineRunner {
    private final UserRepository users;
    private final AuthService auth;

    public DemoPasswordInitializer(UserRepository users, AuthService auth) {
        this.users = users; this.auth = auth;
    }

    @Override
    public void run(String... args) {
        String hash = auth.encoder().encode("demo123");
        users.findAll().forEach(u -> {
            if ("TEMP".equals(u.getPasswordHash())) {
                u.setPasswordHash(hash);
                users.save(u);
            }
        });
    }
}

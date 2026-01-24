package com.example.backend_api.service;

import com.example.backend_api.model.User;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.List;

@Service
public class TokenStore {
    private static final String SECRET = "rezervari-online-secret-key-2024-super-secure-32chars!!";
    private static final long EXPIRATION = 7 * 24 * 60 * 60 * 1000L; // 7 days

    private final SecretKey key = Keys.hmacShaKeyFor(SECRET.getBytes(StandardCharsets.UTF_8));

    public String issue(User user) {
        Date now = new Date();
        Date expiry = new Date(now.getTime() + EXPIRATION);

        List<Integer> adminRestaurantIds = user.getRole().name().equals("ADMIN")
            ? List.of(1) // Will be filled by caller
            : List.of();

        return Jwts.builder()
                .subject(String.valueOf(user.getId()))
                .claim("userId", user.getId())
                .claim("role", user.getRole().name())
                .claim("adminRestaurantIds", adminRestaurantIds)
                .issuedAt(now)
                .expiration(expiry)
                .signWith(key)
                .compact();
    }

    public Integer userIdFromToken(String token) {
        try {
            var claims = Jwts.parser()
                    .verifyWith(key)
                    .build()
                    .parseSignedClaims(token);
            return Integer.parseInt(claims.getPayload().getSubject());
        } catch (Exception e) {
            return null;
        }
    }

    public String roleFromToken(String token) {
        try {
            var claims = Jwts.parser()
                    .verifyWith(key)
                    .build()
                    .parseSignedClaims(token);
            return claims.getPayload().get("role", String.class);
        } catch (Exception e) {
            return null;
        }
    }

    @SuppressWarnings("unchecked")
    public List<Integer> adminRestaurantIdsFromToken(String token) {
        try {
            var claims = Jwts.parser()
                    .verifyWith(key)
                    .build()
                    .parseSignedClaims(token);
            return claims.getPayload().get("adminRestaurantIds", List.class);
        } catch (Exception e) {
            return List.of();
        }
    }
}

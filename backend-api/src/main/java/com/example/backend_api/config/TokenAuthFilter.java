package com.example.backend_api.config;

import com.example.backend_api.model.User;
import com.example.backend_api.repo.UserRepository;
import com.example.backend_api.service.TokenStore;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

public class TokenAuthFilter extends OncePerRequestFilter {
    private final TokenStore tokenStore;
    private final UserRepository users;

    public TokenAuthFilter(TokenStore tokenStore, UserRepository users) {
        this.tokenStore = tokenStore;
        this.users = users;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {

        String auth = req.getHeader("Authorization");

        if (auth != null && auth.startsWith("Bearer ")) {
            String token = auth.substring("Bearer ".length()).trim();
            Integer userId = tokenStore.userIdFromToken(token);

            if (userId != null) {
                User u = users.findById(userId).orElse(null);
                if (u != null) {
                    var authorities = List.of(new SimpleGrantedAuthority("ROLE_" + u.getRole().name()));
                    var authentication = new UsernamePasswordAuthenticationToken(u.getId(), null, authorities);
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            }
        }

        chain.doFilter(req, res);
    }
}

package com.example.backend_api.dto;

import java.util.List;

public class LoginResponse {
    public String token;
    public String role;
    public List<Integer> adminRestaurantIds;

    public LoginResponse(String token, String role, List<Integer> adminRestaurantIds) {
        this.token = token;
        this.role = role;
        this.adminRestaurantIds = adminRestaurantIds;
    }
}

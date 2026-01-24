package com.example.backend_api.dto;

import jakarta.validation.constraints.*;

public class LoginRequest {
    @Email @NotBlank public String email;
    @NotBlank public String password;
}

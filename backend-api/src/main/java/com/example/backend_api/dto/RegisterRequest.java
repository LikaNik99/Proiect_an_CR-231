package com.example.backend_api.dto;

import jakarta.validation.constraints.*;

public class RegisterRequest {
    @NotBlank public String fullName;
    @Email @NotBlank public String email;
    @NotBlank @Size(min = 6) public String password;
}

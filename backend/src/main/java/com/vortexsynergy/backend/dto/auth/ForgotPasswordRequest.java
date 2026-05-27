package com.vortexsynergy.backend.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record ForgotPasswordRequest(
    @Email(message = "Valid email is required")
    @NotBlank(message = "Email is required")
    String email
) {
}

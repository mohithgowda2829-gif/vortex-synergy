package com.vortexsynergy.backend.dto.auth;

import com.vortexsynergy.backend.model.enums.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
    @NotBlank(message = "Full name is required")
    String fullName,
    @Email(message = "Valid email is required")
    @NotBlank(message = "Email is required")
    String email,
    @NotBlank(message = "Phone is required")
    @Pattern(regexp = "^[0-9+\\- ]{10,15}$", message = "Phone number format is invalid")
    String phone,
    @NotBlank(message = "Password is required")
    @Size(min = 8, message = "Password must be at least 8 characters")
    String password,
    @NotNull(message = "Role is required")
    Role role
) {
}

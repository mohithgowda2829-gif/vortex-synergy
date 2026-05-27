package com.vortexsynergy.backend.dto.user;

import jakarta.validation.constraints.NotBlank;

public record PlaceholderVerificationRequest(
    @NotBlank(message = "Channel is required")
    String channel,
    @NotBlank(message = "Verification code is required")
    String code
) {
}

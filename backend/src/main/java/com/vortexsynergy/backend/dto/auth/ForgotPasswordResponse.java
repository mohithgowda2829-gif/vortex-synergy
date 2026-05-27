package com.vortexsynergy.backend.dto.auth;

import java.time.Instant;

public record ForgotPasswordResponse(
    String message,
    String resetToken,
    Instant expiresAt
) {
}

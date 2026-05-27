package com.vortexsynergy.backend.dto.auth;

import com.vortexsynergy.backend.dto.user.UserResponse;

public record AuthResponse(
    String token,
    UserResponse user
) {
}

package com.vortexsynergy.backend.dto.user;

import com.vortexsynergy.backend.model.User;
import com.vortexsynergy.backend.model.enums.Role;
import java.util.UUID;

public record UserResponse(
    UUID id,
    String fullName,
    String email,
    String phone,
    Role role,
    boolean accountVerified,
    boolean emailVerified,
    boolean phoneVerified,
    boolean adminApproved,
    boolean active
) {
    public static UserResponse from(User user) {
        return new UserResponse(
            user.getId(),
            user.getFullName(),
            user.getEmail(),
            user.getPhone(),
            user.getRole(),
            user.isAccountVerified(),
            user.isEmailVerified(),
            user.isPhoneVerified(),
            user.isAdminApproved(),
            user.isActive()
        );
    }
}

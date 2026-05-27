package com.vortexsynergy.backend.service;

import com.vortexsynergy.backend.dto.user.PlaceholderVerificationRequest;
import com.vortexsynergy.backend.dto.user.UserResponse;
import com.vortexsynergy.backend.exception.BadRequestException;
import com.vortexsynergy.backend.exception.NotFoundException;
import com.vortexsynergy.backend.model.User;
import com.vortexsynergy.backend.model.Verification;
import com.vortexsynergy.backend.model.enums.Role;
import com.vortexsynergy.backend.model.enums.VerificationStatus;
import com.vortexsynergy.backend.model.enums.VerificationTargetType;
import com.vortexsynergy.backend.model.enums.VerificationType;
import com.vortexsynergy.backend.repository.UserRepository;
import com.vortexsynergy.backend.repository.VerificationRepository;
import com.vortexsynergy.backend.security.UserPrincipal;
import jakarta.transaction.Transactional;
import java.time.Instant;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final VerificationRepository verificationRepository;
    private final AuditService auditService;

    public UserResponse getCurrentUser(UserPrincipal principal) {
        return UserResponse.from(getCurrentUserEntity(principal));
    }

    public User getCurrentUserEntity(UserPrincipal principal) {
        return userRepository.findById(principal.getId())
            .orElseThrow(() -> new NotFoundException("User not found"));
    }

    @Transactional
    public UserResponse verifyPlaceholder(UserPrincipal principal, PlaceholderVerificationRequest request) {
        User user = getCurrentUserEntity(principal);
        String channel = request.channel().trim().toUpperCase();

        if (request.code().trim().length() < 4) {
            throw new BadRequestException("Placeholder verification code is invalid");
        }

        VerificationType verificationType;
        switch (channel) {
            case "EMAIL" -> {
                user.setEmailVerified(true);
                verificationType = VerificationType.EMAIL;
            }
            case "PHONE" -> {
                user.setPhoneVerified(true);
                verificationType = VerificationType.PHONE;
            }
            default -> throw new BadRequestException("Channel must be EMAIL or PHONE");
        }

        user.setAccountVerified(isAccountVerified(user));
        userRepository.save(user);
        updateVerificationStatus(user, verificationType, VerificationStatus.APPROVED, "Placeholder verification completed");

        auditService.log(user, "USER_VERIFIED_" + channel, "USER", user.getId().toString(), "Placeholder verification completed");
        return UserResponse.from(user);
    }

    public boolean isAccountVerified(User user) {
        boolean contactVerified = user.isEmailVerified() && user.isPhoneVerified();
        if (user.getRole() == Role.DOCTOR_PHARMACIST) {
            return contactVerified && user.isAdminApproved();
        }
        return contactVerified;
    }

    private void updateVerificationStatus(User user, VerificationType verificationType, VerificationStatus status, String note) {
        Verification verification = verificationRepository
            .findFirstByTargetTypeAndTargetIdAndVerificationTypeOrderByCreatedAtDesc(
                VerificationTargetType.USER,
                user.getId(),
                verificationType
            )
            .orElseGet(() -> Verification.builder()
                .targetType(VerificationTargetType.USER)
                .targetId(user.getId())
                .verificationType(verificationType)
                .requestedBy(user)
                .build());

        verification.setStatus(status);
        verification.setReviewedBy(user);
        verification.setReviewedAt(Instant.now());
        verification.setNote(note);
        verificationRepository.save(verification);
    }
}

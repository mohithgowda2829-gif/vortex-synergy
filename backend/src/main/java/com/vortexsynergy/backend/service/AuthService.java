package com.vortexsynergy.backend.service;

import com.vortexsynergy.backend.dto.auth.AuthResponse;
import com.vortexsynergy.backend.dto.auth.ForgotPasswordRequest;
import com.vortexsynergy.backend.dto.auth.ForgotPasswordResponse;
import com.vortexsynergy.backend.dto.auth.LoginRequest;
import com.vortexsynergy.backend.dto.auth.RegisterRequest;
import com.vortexsynergy.backend.dto.auth.ResetPasswordRequest;
import com.vortexsynergy.backend.dto.common.ApiMessageResponse;
import com.vortexsynergy.backend.dto.user.UserResponse;
import com.vortexsynergy.backend.exception.BadRequestException;
import com.vortexsynergy.backend.exception.ForbiddenException;
import com.vortexsynergy.backend.model.PasswordResetToken;
import com.vortexsynergy.backend.model.User;
import com.vortexsynergy.backend.model.Verification;
import com.vortexsynergy.backend.model.enums.Role;
import com.vortexsynergy.backend.model.enums.VerificationStatus;
import com.vortexsynergy.backend.model.enums.VerificationTargetType;
import com.vortexsynergy.backend.model.enums.VerificationType;
import com.vortexsynergy.backend.repository.PasswordResetTokenRepository;
import com.vortexsynergy.backend.repository.UserRepository;
import com.vortexsynergy.backend.repository.VerificationRepository;
import com.vortexsynergy.backend.security.JwtService;
import com.vortexsynergy.backend.security.UserPrincipal;
import jakarta.transaction.Transactional;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.HexFormat;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final VerificationRepository verificationRepository;
    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;
    private final AuditService auditService;
    private final SecureRandom secureRandom = new SecureRandom();

    @Value("${app.security.password-reset-token-hours}")
    private long passwordResetTokenHours;

    @Value("${app.security.expose-password-reset-token}")
    private boolean exposePasswordResetToken;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String email = request.email().trim().toLowerCase();
        String phone = request.phone().trim();

        if (request.role() == Role.ADMIN) {
            throw new BadRequestException("Admin accounts cannot be registered through the public API");
        }
        if (userRepository.findByEmailIgnoreCase(email).isPresent()) {
            throw new BadRequestException("Email is already in use");
        }
        if (userRepository.findByPhone(phone).isPresent()) {
            throw new BadRequestException("Phone is already in use");
        }

        User user = User.builder()
            .fullName(request.fullName().trim())
            .email(email)
            .phone(phone)
            .passwordHash(passwordEncoder.encode(request.password()))
            .role(request.role())
            .accountVerified(false)
            .emailVerified(false)
            .phoneVerified(false)
            .adminApproved(request.role() != Role.DOCTOR_PHARMACIST)
            .active(true)
            .build();

        userRepository.save(user);

        createVerification(user, VerificationType.EMAIL, VerificationStatus.PENDING, "Email verification pending");
        createVerification(user, VerificationType.PHONE, VerificationStatus.PENDING, "Phone verification pending");
        if (user.getRole() == Role.DOCTOR_PHARMACIST) {
            createVerification(user, VerificationType.PROFESSIONAL_ACCOUNT, VerificationStatus.PENDING, "Awaiting admin approval");
        }

        auditService.log(user, "USER_REGISTERED", "USER", user.getId().toString(), "New account created");
        return new AuthResponse(jwtService.generateToken(new UserPrincipal(user)), UserResponse.from(user));
    }

    public AuthResponse login(LoginRequest request) {
        String email = request.email().trim().toLowerCase();
        authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(email, request.password()));

        User user = userRepository.findByEmailIgnoreCase(email)
            .orElseThrow(() -> new BadRequestException("Invalid credentials"));

        if (!user.isActive()) {
            throw new ForbiddenException("Account is inactive");
        }

        auditService.log(user, "USER_LOGGED_IN", "USER", user.getId().toString(), "Successful login");
        return new AuthResponse(jwtService.generateToken(new UserPrincipal(user)), UserResponse.from(user));
    }

    @Transactional
    public ForgotPasswordResponse requestPasswordReset(ForgotPasswordRequest request) {
        String email = request.email().trim().toLowerCase();
        String message = "If an active account exists for that email, password reset instructions were generated.";
        User user = userRepository.findByEmailIgnoreCase(email).orElse(null);

        if (user == null || !user.isActive()) {
            return new ForgotPasswordResponse(message, null, null);
        }

        Instant now = Instant.now();
        invalidateActiveResetTokens(user, now);

        String rawToken = generateResetToken();
        PasswordResetToken resetToken = passwordResetTokenRepository.save(
            PasswordResetToken.builder()
                .user(user)
                .tokenHash(hashResetToken(rawToken))
                .expiresAt(now.plus(passwordResetTokenHours, ChronoUnit.HOURS))
                .build()
        );

        auditService.log(user, "PASSWORD_RESET_REQUESTED", "USER", user.getId().toString(), "Password reset requested");
        return new ForgotPasswordResponse(
            message,
            exposePasswordResetToken ? rawToken : null,
            exposePasswordResetToken ? resetToken.getExpiresAt() : null
        );
    }

    @Transactional
    public ApiMessageResponse resetPassword(ResetPasswordRequest request) {
        if (!request.newPassword().equals(request.confirmPassword())) {
            throw new BadRequestException("Password confirmation does not match");
        }

        PasswordResetToken resetToken = passwordResetTokenRepository.findByTokenHash(hashResetToken(request.token().trim()))
            .orElseThrow(() -> new BadRequestException("Password reset token is invalid or expired"));

        if (resetToken.getUsedAt() != null || resetToken.getExpiresAt().isBefore(Instant.now())) {
            throw new BadRequestException("Password reset token is invalid or expired");
        }
        if (!resetToken.getUser().isActive()) {
            throw new ForbiddenException("Account is inactive");
        }

        Instant now = Instant.now();
        resetToken.getUser().setPasswordHash(passwordEncoder.encode(request.newPassword()));
        userRepository.save(resetToken.getUser());

        resetToken.setUsedAt(now);
        passwordResetTokenRepository.save(resetToken);
        invalidateActiveResetTokens(resetToken.getUser(), now);

        auditService.log(
            resetToken.getUser(),
            "PASSWORD_RESET_COMPLETED",
            "USER",
            resetToken.getUser().getId().toString(),
            "Password reset completed"
        );
        return new ApiMessageResponse("Password reset successfully. Please sign in with your new password.");
    }

    private void createVerification(User user, VerificationType verificationType, VerificationStatus status, String note) {
        verificationRepository.save(Verification.builder()
            .targetType(VerificationTargetType.USER)
            .targetId(user.getId())
            .verificationType(verificationType)
            .status(status)
            .requestedBy(user)
            .note(note)
            .build());
    }

    private void invalidateActiveResetTokens(User user, Instant now) {
        List<PasswordResetToken> activeTokens = passwordResetTokenRepository
            .findByUserIdAndUsedAtIsNullAndExpiresAtAfter(user.getId(), now);
        for (PasswordResetToken token : activeTokens) {
            token.setUsedAt(now);
        }
        passwordResetTokenRepository.saveAll(activeTokens);
    }

    private String generateResetToken() {
        byte[] bytes = new byte[32];
        secureRandom.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private String hashResetToken(String rawToken) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(rawToken.getBytes(java.nio.charset.StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }
}

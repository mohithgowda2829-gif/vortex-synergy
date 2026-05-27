package com.vortexsynergy.backend.controller;

import com.vortexsynergy.backend.dto.auth.AuthResponse;
import com.vortexsynergy.backend.dto.auth.ForgotPasswordRequest;
import com.vortexsynergy.backend.dto.auth.ForgotPasswordResponse;
import com.vortexsynergy.backend.dto.auth.LoginRequest;
import com.vortexsynergy.backend.dto.auth.RegisterRequest;
import com.vortexsynergy.backend.dto.auth.ResetPasswordRequest;
import com.vortexsynergy.backend.dto.common.ApiMessageResponse;
import com.vortexsynergy.backend.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public AuthResponse register(@Valid @RequestBody RegisterRequest request) {
        return authService.register(request);
    }

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest request) {
        return authService.login(request);
    }

    @PostMapping("/forgot-password")
    public ForgotPasswordResponse forgotPassword(@Valid @RequestBody ForgotPasswordRequest request) {
        return authService.requestPasswordReset(request);
    }

    @PostMapping("/reset-password")
    public ApiMessageResponse resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        return authService.resetPassword(request);
    }
}

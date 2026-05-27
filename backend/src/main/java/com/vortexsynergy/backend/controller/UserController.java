package com.vortexsynergy.backend.controller;

import com.vortexsynergy.backend.dto.user.PlaceholderVerificationRequest;
import com.vortexsynergy.backend.dto.user.UserResponse;
import com.vortexsynergy.backend.security.UserPrincipal;
import com.vortexsynergy.backend.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/me")
    public UserResponse me(@AuthenticationPrincipal UserPrincipal principal) {
        return userService.getCurrentUser(principal);
    }

    @PostMapping("/me/verify-placeholder")
    public UserResponse verifyPlaceholder(
        @AuthenticationPrincipal UserPrincipal principal,
        @Valid @RequestBody PlaceholderVerificationRequest request
    ) {
        return userService.verifyPlaceholder(principal, request);
    }
}

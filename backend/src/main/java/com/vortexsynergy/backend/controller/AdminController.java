package com.vortexsynergy.backend.controller;

import com.vortexsynergy.backend.dto.admin.AdminDecisionRequest;
import com.vortexsynergy.backend.dto.admin.VerificationResponse;
import com.vortexsynergy.backend.dto.common.ApiMessageResponse;
import com.vortexsynergy.backend.dto.dashboard.DashboardSummaryResponse;
import com.vortexsynergy.backend.dto.resource.ResourceResponse;
import com.vortexsynergy.backend.security.UserPrincipal;
import com.vortexsynergy.backend.service.AdminService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;

    @GetMapping("/verifications/pending")
    public List<VerificationResponse> pendingVerifications() {
        return adminService.getPendingVerifications();
    }

    @PostMapping("/verifications/{verificationId}/decision")
    public VerificationResponse decideVerification(
        @AuthenticationPrincipal UserPrincipal principal,
        @PathVariable UUID verificationId,
        @Valid @RequestBody AdminDecisionRequest request
    ) {
        return adminService.decideVerification(principal, verificationId, request);
    }

    @GetMapping("/resources")
    public List<ResourceResponse> resources() {
        return adminService.getAllResources();
    }

    @PostMapping("/resources/{resourceId}/remove")
    public ApiMessageResponse removeResource(
        @AuthenticationPrincipal UserPrincipal principal,
        @PathVariable UUID resourceId
    ) {
        return adminService.removeResource(principal, resourceId);
    }

    @GetMapping("/analytics")
    public DashboardSummaryResponse analytics() {
        return adminService.getAnalytics();
    }
}

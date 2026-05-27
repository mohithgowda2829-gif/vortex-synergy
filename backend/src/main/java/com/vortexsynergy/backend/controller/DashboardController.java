package com.vortexsynergy.backend.controller;

import com.vortexsynergy.backend.dto.dashboard.DashboardSummaryResponse;
import com.vortexsynergy.backend.dto.dashboard.DonorCertificateDetailResponse;
import com.vortexsynergy.backend.dto.dashboard.DonorCertificateResponse;
import com.vortexsynergy.backend.dto.dashboard.RoleDashboardResponse;
import com.vortexsynergy.backend.security.UserPrincipal;
import com.vortexsynergy.backend.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService dashboardService;

    @GetMapping("/summary")
    public DashboardSummaryResponse summary() {
        return dashboardService.getSummary();
    }

    @GetMapping("/role-summary")
    public RoleDashboardResponse roleSummary(@AuthenticationPrincipal UserPrincipal principal) {
        return dashboardService.getRoleSummary(principal);
    }

    @GetMapping("/donor-certificate")
    public DonorCertificateResponse donorCertificate(@AuthenticationPrincipal UserPrincipal principal) {
        return dashboardService.getDonorCertificate(principal);
    }

    @GetMapping("/donor-certificate/detail")
    public DonorCertificateDetailResponse donorCertificateDetail(@AuthenticationPrincipal UserPrincipal principal) {
        return dashboardService.getDonorCertificateDetail(principal);
    }

    @GetMapping("/donor-certificate/download")
    public ResponseEntity<String> downloadDonorCertificate(@AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"donor-certificate.html\"")
            .contentType(MediaType.TEXT_HTML)
            .body(dashboardService.downloadDonorCertificateHtml(principal));
    }
}

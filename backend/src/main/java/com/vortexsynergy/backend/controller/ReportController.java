package com.vortexsynergy.backend.controller;

import com.vortexsynergy.backend.security.UserPrincipal;
import com.vortexsynergy.backend.service.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/reports")
@RequiredArgsConstructor
public class ReportController {

    private final ReportService reportService;

    @GetMapping("/donations/csv")
    public ResponseEntity<String> donations(@AuthenticationPrincipal UserPrincipal principal) {
        return csv("donations.csv", reportService.donationsCsv(principal));
    }

    @GetMapping("/claims/csv")
    public ResponseEntity<String> claims(@AuthenticationPrincipal UserPrincipal principal) {
        return csv("claims.csv", reportService.claimsCsv(principal));
    }

    @GetMapping("/expiry/csv")
    public ResponseEntity<String> expiry(@AuthenticationPrincipal UserPrincipal principal) {
        return csv("expiry.csv", reportService.expiryCsv(principal));
    }

    @GetMapping("/medicine/csv")
    public ResponseEntity<String> medicine(@AuthenticationPrincipal UserPrincipal principal) {
        return csv("medicine.csv", reportService.medicineCsv(principal));
    }

    @GetMapping("/delivery/csv")
    public ResponseEntity<String> delivery(@AuthenticationPrincipal UserPrincipal principal) {
        return csv("delivery.csv", reportService.deliveryCsv(principal));
    }

    private ResponseEntity<String> csv(String filename, String body) {
        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
            .contentType(MediaType.parseMediaType("text/csv"))
            .body(body);
    }
}

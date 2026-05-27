package com.vortexsynergy.backend.controller;

import com.vortexsynergy.backend.dto.resource.MedicalVerificationRequest;
import com.vortexsynergy.backend.dto.resource.ResourceResponse;
import com.vortexsynergy.backend.security.UserPrincipal;
import com.vortexsynergy.backend.service.MedicalVerificationService;
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
@RequestMapping("/api/medical")
@RequiredArgsConstructor
public class MedicalVerificationController {

    private final MedicalVerificationService medicalVerificationService;

    @GetMapping("/pending")
    public List<ResourceResponse> pendingResources() {
        return medicalVerificationService.getPendingMedicineResources();
    }

    @GetMapping("/history")
    public List<ResourceResponse> reviewHistory(@AuthenticationPrincipal UserPrincipal principal) {
        return medicalVerificationService.getReviewedMedicineResources(principal);
    }

    @PostMapping("/verify/{resourceId}")
    public ResourceResponse verify(
        @AuthenticationPrincipal UserPrincipal principal,
        @PathVariable UUID resourceId,
        @Valid @RequestBody MedicalVerificationRequest request
    ) {
        return medicalVerificationService.verifyMedicine(principal, resourceId, request);
    }

    @PostMapping("/reject/{resourceId}")
    public ResourceResponse reject(
        @AuthenticationPrincipal UserPrincipal principal,
        @PathVariable UUID resourceId,
        @Valid @RequestBody MedicalVerificationRequest request
    ) {
        return medicalVerificationService.rejectMedicine(principal, resourceId, request);
    }
}

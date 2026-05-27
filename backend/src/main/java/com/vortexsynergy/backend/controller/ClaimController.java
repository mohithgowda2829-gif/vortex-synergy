package com.vortexsynergy.backend.controller;

import com.vortexsynergy.backend.dto.claim.ClaimCancelRequest;
import com.vortexsynergy.backend.dto.claim.ClaimConfirmRequest;
import com.vortexsynergy.backend.dto.claim.ClaimRequest;
import com.vortexsynergy.backend.dto.claim.ClaimResponse;
import com.vortexsynergy.backend.dto.claim.HandoverRequest;
import com.vortexsynergy.backend.dto.claim.PickupApprovalRequest;
import com.vortexsynergy.backend.dto.claim.PickupDetailsRequest;
import com.vortexsynergy.backend.security.UserPrincipal;
import com.vortexsynergy.backend.service.ClaimService;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/claims")
@RequiredArgsConstructor
public class ClaimController {

    private final ClaimService claimService;

    @PostMapping("/request")
    public ClaimResponse requestClaim(
        @AuthenticationPrincipal UserPrincipal principal,
        @Valid @RequestBody ClaimRequest request
    ) {
        return claimService.requestClaim(principal, request);
    }

    @PostMapping("/confirm")
    public ClaimResponse confirmClaim(
        @AuthenticationPrincipal UserPrincipal principal,
        @Valid @RequestBody ClaimConfirmRequest request
    ) {
        return claimService.confirmClaim(principal, request);
    }

    @PostMapping("/cancel")
    public ClaimResponse cancelClaim(
        @AuthenticationPrincipal UserPrincipal principal,
        @Valid @RequestBody ClaimCancelRequest request
    ) {
        return claimService.cancelClaim(principal, request);
    }

    @PostMapping("/pickup-details")
    public ClaimResponse submitPickupDetails(
        @AuthenticationPrincipal UserPrincipal principal,
        @Valid @RequestBody PickupDetailsRequest request
    ) {
        return claimService.submitPickupDetails(principal, request);
    }

    @PostMapping("/approve-pickup-details")
    public ClaimResponse approvePickupDetails(
        @AuthenticationPrincipal UserPrincipal principal,
        @Valid @RequestBody PickupApprovalRequest request
    ) {
        return claimService.approvePickupDetails(principal, request);
    }

    @PostMapping("/handover")
    public ClaimResponse handoverClaim(
        @AuthenticationPrincipal UserPrincipal principal,
        @Valid @RequestBody HandoverRequest request
    ) {
        return claimService.handoverClaim(principal, request);
    }

    @GetMapping("/my")
    public List<ClaimResponse> myClaims(@AuthenticationPrincipal UserPrincipal principal) {
        return claimService.getMyClaims(principal);
    }

    @GetMapping("/donor")
    public List<ClaimResponse> donorClaims(@AuthenticationPrincipal UserPrincipal principal) {
        return claimService.getDonorClaims(principal);
    }
}

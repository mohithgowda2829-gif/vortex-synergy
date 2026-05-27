package com.vortexsynergy.backend.controller;

import com.vortexsynergy.backend.dto.delivery.DeliveryAssignRequest;
import com.vortexsynergy.backend.dto.delivery.DeliveryFailRequest;
import com.vortexsynergy.backend.dto.delivery.DeliveryResponse;
import com.vortexsynergy.backend.dto.delivery.DeliveryStatusUpdateRequest;
import com.vortexsynergy.backend.security.UserPrincipal;
import com.vortexsynergy.backend.service.DeliveryService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/deliveries")
@RequiredArgsConstructor
public class DeliveryController {

    private final DeliveryService deliveryService;

    @PostMapping("/assign")
    public DeliveryResponse assign(
        @AuthenticationPrincipal UserPrincipal principal,
        @Valid @RequestBody DeliveryAssignRequest request
    ) {
        return deliveryService.assignDelivery(principal, request);
    }

    @GetMapping("/{claimId}")
    public DeliveryResponse byClaim(
        @AuthenticationPrincipal UserPrincipal principal,
        @PathVariable UUID claimId
    ) {
        return deliveryService.getByClaim(principal, claimId);
    }

    @PostMapping("/pickup-approve")
    public DeliveryResponse pickupApprove(
        @AuthenticationPrincipal UserPrincipal principal,
        @Valid @RequestBody DeliveryStatusUpdateRequest request
    ) {
        return deliveryService.pickupApprove(principal, request);
    }

    @PostMapping("/in-transit")
    public DeliveryResponse inTransit(
        @AuthenticationPrincipal UserPrincipal principal,
        @Valid @RequestBody DeliveryStatusUpdateRequest request
    ) {
        return deliveryService.markInTransit(principal, request);
    }

    @PostMapping("/delivered")
    public DeliveryResponse delivered(
        @AuthenticationPrincipal UserPrincipal principal,
        @Valid @RequestBody DeliveryStatusUpdateRequest request
    ) {
        return deliveryService.markDelivered(principal, request);
    }

    @PostMapping("/confirm-receipt")
    public DeliveryResponse confirmReceipt(
        @AuthenticationPrincipal UserPrincipal principal,
        @Valid @RequestBody DeliveryStatusUpdateRequest request
    ) {
        return deliveryService.confirmReceipt(principal, request);
    }

    @PostMapping("/fail")
    public DeliveryResponse fail(
        @AuthenticationPrincipal UserPrincipal principal,
        @Valid @RequestBody DeliveryFailRequest request
    ) {
        return deliveryService.failDelivery(principal, request);
    }

    @GetMapping("/receiver")
    public List<DeliveryResponse> receiverDeliveries(@AuthenticationPrincipal UserPrincipal principal) {
        return deliveryService.getReceiverDeliveries(principal);
    }

    @GetMapping("/donor")
    public List<DeliveryResponse> donorDeliveries(@AuthenticationPrincipal UserPrincipal principal) {
        return deliveryService.getDonorDeliveries(principal);
    }
}

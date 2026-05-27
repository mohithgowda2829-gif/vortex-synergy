package com.vortexsynergy.backend.dto.claim;

import com.vortexsynergy.backend.model.Claim;
import com.vortexsynergy.backend.model.enums.ClaimStatus;
import com.vortexsynergy.backend.model.enums.ResourceType;
import java.time.Instant;
import java.util.UUID;

public record ClaimResponse(
    UUID id,
    UUID resourceId,
    String resourceTitle,
    String receiverName,
    ResourceType resourceType,
    Integer quantity,
    ClaimStatus status,
    String pickupCode,
    Instant reservedAt,
    Instant reservationExpiresAt,
    Instant confirmedAt,
    Instant claimedAt,
    boolean deliveryRequested,
    String pickupPersonName,
    String pickupPersonPhone,
    String pickupVehicleNumber,
    String pickupVehicleDetails,
    Instant pickupDetailsSubmittedAt,
    boolean pickupDetailsApproved,
    Instant pickupDetailsApprovedAt,
    Integer priorityScore,
    String priorityExplanation,
    boolean pickupConfirmedByReceiver,
    boolean handoverConfirmed
) {
    public static ClaimResponse from(Claim claim, boolean includePickupCode) {
        return new ClaimResponse(
            claim.getId(),
            claim.getResource().getId(),
            claim.getResource().getTitle(),
            claim.getReceiver().getFullName(),
            claim.getResource().getResourceType(),
            claim.getQuantity(),
            claim.getStatus(),
            includePickupCode ? claim.getPickupCode() : null,
            claim.getReservedAt(),
            claim.getReservationExpiresAt(),
            claim.getConfirmedAt(),
            claim.getClaimedAt(),
            claim.isDeliveryRequested(),
            claim.getPickupPersonName(),
            claim.getPickupPersonPhone(),
            claim.getPickupVehicleNumber(),
            claim.getPickupVehicleDetails(),
            claim.getPickupDetailsSubmittedAt(),
            Boolean.TRUE.equals(claim.getPickupDetailsApproved()),
            claim.getPickupDetailsApprovedAt(),
            claim.getPriorityScore(),
            claim.getPriorityExplanation(),
            claim.isPickupConfirmedByReceiver(),
            claim.isHandoverConfirmed()
        );
    }
}

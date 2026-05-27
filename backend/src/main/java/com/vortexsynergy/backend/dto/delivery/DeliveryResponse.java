package com.vortexsynergy.backend.dto.delivery;

import com.vortexsynergy.backend.model.Delivery;
import com.vortexsynergy.backend.model.enums.DeliveryStatus;
import java.time.Instant;
import java.util.UUID;

public record DeliveryResponse(
    UUID id,
    UUID claimId,
    UUID receiverId,
    UUID donorId,
    String resourceTitle,
    String receiverName,
    String donorName,
    String orderNumber,
    String vehicleNumber,
    String agentName,
    String agentMobile,
    DeliveryStatus status,
    Instant pickupApprovedAt,
    Instant deliveredAt,
    Instant receiverConfirmedAt,
    String failedReason,
    Double lastLatitude,
    Double lastLongitude,
    Instant lastLocationUpdateAt,
    String notes
) {
    public static DeliveryResponse from(Delivery delivery) {
        return new DeliveryResponse(
            delivery.getId(),
            delivery.getClaim().getId(),
            delivery.getClaim().getReceiver().getId(),
            delivery.getClaim().getResource().getDonor().getId(),
            delivery.getClaim().getResource().getTitle(),
            delivery.getReceiver() != null
                ? delivery.getReceiver().getFullName()
                : delivery.getClaim().getReceiver().getFullName(),
            delivery.getClaim().getResource().getDonor().getFullName(),
            delivery.getOrderNumber(),
            delivery.getVehicleNumber(),
            delivery.getAgentName(),
            delivery.getAgentMobile(),
            delivery.getStatus(),
            delivery.getPickupApprovedAt(),
            delivery.getDeliveredAt(),
            delivery.getReceiverConfirmedAt(),
            delivery.getFailedReason(),
            delivery.getLastLatitude(),
            delivery.getLastLongitude(),
            delivery.getLastLocationUpdateAt(),
            delivery.getNotes()
        );
    }
}

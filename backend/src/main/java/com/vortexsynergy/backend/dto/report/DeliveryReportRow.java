package com.vortexsynergy.backend.dto.report;

import com.vortexsynergy.backend.model.enums.DeliveryStatus;
import java.time.Instant;
import java.util.UUID;

public record DeliveryReportRow(
    UUID deliveryId,
    UUID claimId,
    String resourceTitle,
    String receiver,
    String orderNumber,
    String agentName,
    String agentMobile,
    String vehicleNumber,
    DeliveryStatus status,
    Instant pickupApprovedAt,
    Instant deliveredAt,
    String failedReason
) {
}

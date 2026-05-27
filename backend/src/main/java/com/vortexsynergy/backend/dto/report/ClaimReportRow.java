package com.vortexsynergy.backend.dto.report;

import com.vortexsynergy.backend.model.enums.ClaimStatus;
import java.time.Instant;
import java.util.UUID;

public record ClaimReportRow(
    UUID claimId,
    String resourceTitle,
    String receiver,
    ClaimStatus status,
    Integer quantity,
    boolean deliveryRequested,
    Integer priorityScore,
    String priorityExplanation,
    Instant createdAt
) {
}

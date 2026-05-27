package com.vortexsynergy.backend.dto.report;

import com.vortexsynergy.backend.model.enums.ResourceStatus;
import com.vortexsynergy.backend.model.enums.ResourceType;
import java.time.Instant;
import java.util.UUID;

public record DonationReportRow(
    UUID resourceId,
    String title,
    ResourceType type,
    String donor,
    ResourceStatus status,
    String city,
    String area,
    Integer quantity,
    Integer available,
    Instant createdAt
) {
}

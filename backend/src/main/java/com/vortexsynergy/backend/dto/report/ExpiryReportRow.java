package com.vortexsynergy.backend.dto.report;

import com.vortexsynergy.backend.model.enums.ResourceStatus;
import com.vortexsynergy.backend.model.enums.ResourceType;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

public record ExpiryReportRow(
    UUID resourceId,
    String title,
    ResourceType type,
    ResourceStatus status,
    String city,
    String area,
    LocalDateTime expiresAt,
    LocalDate medicineExpiryDate
) {
}

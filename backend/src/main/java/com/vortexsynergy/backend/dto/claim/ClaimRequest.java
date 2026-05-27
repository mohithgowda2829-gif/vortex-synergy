package com.vortexsynergy.backend.dto.claim;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record ClaimRequest(
    @NotNull(message = "Resource id is required")
    UUID resourceId,
    @NotNull(message = "Quantity is required")
    @Min(value = 1, message = "Quantity must be at least 1")
    Integer quantity,
    Boolean deliveryRequested,
    Boolean urgentNeed,
    Boolean vulnerableReceiver
) {
}

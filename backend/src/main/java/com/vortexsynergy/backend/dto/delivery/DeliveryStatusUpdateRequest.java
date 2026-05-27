package com.vortexsynergy.backend.dto.delivery;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public record DeliveryStatusUpdateRequest(
    @NotNull(message = "Claim id is required")
    UUID claimId,
    @DecimalMin(value = "-90.0", message = "Latitude must be at least -90")
    @DecimalMax(value = "90.0", message = "Latitude must be at most 90")
    Double latitude,
    @DecimalMin(value = "-180.0", message = "Longitude must be at least -180")
    @DecimalMax(value = "180.0", message = "Longitude must be at most 180")
    Double longitude,
    @Size(max = 32, message = "Pickup code must be 32 characters or fewer")
    String pickupCode,
    @Size(max = 1000, message = "Note must be 1000 characters or fewer")
    String note
) {
}

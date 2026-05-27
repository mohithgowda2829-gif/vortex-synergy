package com.vortexsynergy.backend.dto.claim;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record HandoverRequest(
    @NotNull(message = "Claim id is required")
    UUID claimId,
    @NotBlank(message = "Pickup code is required")
    String pickupCode
) {
}

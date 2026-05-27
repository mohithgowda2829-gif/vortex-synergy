package com.vortexsynergy.backend.dto.delivery;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public record DeliveryFailRequest(
    @NotNull(message = "Claim id is required")
    UUID claimId,
    @NotBlank(message = "Failure reason is required")
    @Size(max = 1000, message = "Failure reason must be 1000 characters or fewer")
    String failedReason
) {
}

package com.vortexsynergy.backend.dto.claim;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record ClaimConfirmRequest(
    @NotNull(message = "Claim id is required")
    UUID claimId
) {
}

package com.vortexsynergy.backend.dto.admin;

import jakarta.validation.constraints.NotNull;

public record AdminDecisionRequest(
    @NotNull(message = "Approval decision is required")
    Boolean approved,
    String note
) {
}

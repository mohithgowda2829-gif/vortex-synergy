package com.vortexsynergy.backend.dto.chat;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public record ChatMessageRequest(
    @NotNull(message = "Claim id is required")
    UUID claimId,
    @NotBlank(message = "Message is required")
    @Size(max = 2000, message = "Message must be 2000 characters or fewer")
    String message
) {
}

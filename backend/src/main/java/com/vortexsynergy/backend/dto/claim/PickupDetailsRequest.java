package com.vortexsynergy.backend.dto.claim;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public record PickupDetailsRequest(
    @NotNull(message = "Claim id is required")
    UUID claimId,
    @NotBlank(message = "Pickup person name is required")
    @Size(max = 120, message = "Pickup person name must be 120 characters or fewer")
    String pickupPersonName,
    @NotBlank(message = "Pickup person phone is required")
    @Pattern(regexp = "^[0-9+\\- ]{10,15}$", message = "Phone number format is invalid")
    String pickupPersonPhone,
    @NotBlank(message = "Vehicle number is required")
    @Size(max = 32, message = "Vehicle number must be 32 characters or fewer")
    String pickupVehicleNumber,
    @NotBlank(message = "Vehicle details are required")
    @Size(max = 120, message = "Vehicle details must be 120 characters or fewer")
    String pickupVehicleDetails
) {
}

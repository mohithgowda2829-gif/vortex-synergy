package com.vortexsynergy.backend.dto.delivery;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public record DeliveryAssignRequest(
    @NotNull(message = "Claim id is required")
    UUID claimId,
    @NotBlank(message = "Order number is required")
    @Size(max = 64, message = "Order number must be 64 characters or fewer")
    String orderNumber,
    @NotBlank(message = "Vehicle number is required")
    @Size(max = 32, message = "Vehicle number must be 32 characters or fewer")
    String vehicleNumber,
    @NotBlank(message = "Agent name is required")
    @Size(max = 120, message = "Agent name must be 120 characters or fewer")
    String agentName,
    @NotBlank(message = "Agent mobile number is required")
    @Pattern(regexp = "^[0-9+\\- ]{10,15}$", message = "Phone number format is invalid")
    String agentMobile,
    @DecimalMin(value = "-90.0", message = "Latitude must be at least -90")
    @DecimalMax(value = "90.0", message = "Latitude must be at most 90")
    Double lastLatitude,
    @DecimalMin(value = "-180.0", message = "Longitude must be at least -180")
    @DecimalMax(value = "180.0", message = "Longitude must be at most 180")
    Double lastLongitude,
    @Size(max = 1000, message = "Notes must be 1000 characters or fewer")
    String notes
) {
}

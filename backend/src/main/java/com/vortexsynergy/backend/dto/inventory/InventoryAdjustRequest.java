package com.vortexsynergy.backend.dto.inventory;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public record InventoryAdjustRequest(
    @NotNull(message = "Inventory item id is required")
    UUID inventoryItemId,
    @NotNull(message = "Quantity is required")
    @Min(value = 1, message = "Quantity must be at least 1")
    Integer quantity,
    @Size(max = 120, message = "Branch name must be 120 characters or fewer")
    String branchName,
    @Size(max = 255, message = "Storage location must be 255 characters or fewer")
    String storageLocation,
    @Size(max = 1000, message = "Notes must be 1000 characters or fewer")
    String notes
) {
}

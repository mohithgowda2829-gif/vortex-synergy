package com.vortexsynergy.backend.dto.inventory;

import com.vortexsynergy.backend.model.InventoryItem;
import com.vortexsynergy.backend.model.enums.InventoryStatus;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

public record InventoryItemResponse(
    UUID id,
    UUID resourceId,
    UUID claimId,
    String resourceTitle,
    String resourceType,
    String donorName,
    Integer quantityReceived,
    Integer quantityAvailable,
    Integer quantityConsumed,
    Integer quantityExpired,
    String unit,
    InventoryStatus status,
    String branchName,
    String storageLocation,
    Instant stockedAt,
    Instant lastConsumedAt,
    LocalDateTime foodExpiresAt,
    LocalDate medicineExpiryDate,
    String city,
    String area,
    String notes
) {
    public static InventoryItemResponse from(InventoryItem item) {
        return new InventoryItemResponse(
            item.getId(),
            item.getResource().getId(),
            item.getClaim() == null ? null : item.getClaim().getId(),
            item.getResource().getTitle(),
            item.getResource().getResourceType().name(),
            item.getResource().getDonor().getFullName(),
            item.getQuantityReceived(),
            item.getQuantityAvailable(),
            item.getQuantityConsumed(),
            item.getQuantityExpired(),
            item.getResource().getUnit(),
            item.getStatus(),
            item.getBranchName(),
            item.getStorageLocation(),
            item.getStockedAt(),
            item.getLastConsumedAt(),
            item.getResource().getExpiresAt(),
            item.getResource().getMedicineExpiryDate(),
            item.getResource().getCity(),
            item.getResource().getArea(),
            item.getNotes()
        );
    }
}

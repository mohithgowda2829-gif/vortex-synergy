package com.vortexsynergy.backend.service;

import com.vortexsynergy.backend.dto.inventory.InventoryAdjustRequest;
import com.vortexsynergy.backend.dto.inventory.InventoryItemResponse;
import com.vortexsynergy.backend.exception.BadRequestException;
import com.vortexsynergy.backend.exception.ForbiddenException;
import com.vortexsynergy.backend.exception.NotFoundException;
import com.vortexsynergy.backend.model.Claim;
import com.vortexsynergy.backend.model.InventoryItem;
import com.vortexsynergy.backend.model.Resource;
import com.vortexsynergy.backend.model.User;
import com.vortexsynergy.backend.model.enums.InventoryStatus;
import com.vortexsynergy.backend.model.enums.NotificationType;
import com.vortexsynergy.backend.model.enums.Role;
import com.vortexsynergy.backend.repository.InventoryItemRepository;
import com.vortexsynergy.backend.repository.UserRepository;
import com.vortexsynergy.backend.security.UserPrincipal;
import jakarta.transaction.Transactional;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class InventoryService {

    private final InventoryItemRepository inventoryItemRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    private final AuditService auditService;

    @Transactional
    public void stockClaim(Claim claim) {
        InventoryItem item = inventoryItemRepository.findByClaimId(claim.getId())
            .orElseGet(() -> InventoryItem.builder()
                .claim(claim)
                .receiver(claim.getReceiver())
                .resource(claim.getResource())
                .quantityReceived(claim.getQuantity())
                .quantityAvailable(claim.getQuantity())
                .quantityConsumed(0)
                .quantityExpired(0)
                .status(InventoryStatus.ACTIVE)
                .stockedAt(Instant.now())
                .build());

        item.setReceiver(claim.getReceiver());
        item.setResource(claim.getResource());
        item.setQuantityReceived(claim.getQuantity());
        if (item.getQuantityAvailable() == null) {
            item.setQuantityAvailable(claim.getQuantity());
        }
        recalculateStatus(item);
        inventoryItemRepository.save(item);
    }

    @Transactional
    public List<InventoryItemResponse> mine(UserPrincipal principal) {
        User user = currentUser(principal);
        if (user.getRole() != Role.RECEIVER && user.getRole() != Role.ADMIN) {
            throw new ForbiddenException("Only receiver organizations or admins can view inventory");
        }
        List<InventoryItem> items = user.getRole() == Role.ADMIN
            ? inventoryItemRepository.findAll()
            : inventoryItemRepository.findByReceiverIdOrderByCreatedAtDesc(user.getId());
        items.forEach(this::recalculateStatus);
        inventoryItemRepository.saveAll(items);
        return items.stream()
            .sorted((left, right) -> right.getCreatedAt().compareTo(left.getCreatedAt()))
            .map(InventoryItemResponse::from)
            .toList();
    }

    @Transactional
    public InventoryItemResponse consume(UserPrincipal principal, InventoryAdjustRequest request) {
        InventoryItem item = findOwnedInventory(principal, request.inventoryItemId());
        if (request.quantity() > item.getQuantityAvailable()) {
            throw new BadRequestException("Cannot consume more than available stock");
        }
        item.setQuantityAvailable(item.getQuantityAvailable() - request.quantity());
        item.setQuantityConsumed(item.getQuantityConsumed() + request.quantity());
        item.setLastConsumedAt(Instant.now());
        item.setBranchName(trimToNull(request.branchName()));
        item.setStorageLocation(trimToNull(request.storageLocation()));
        item.setNotes(trimToNull(request.notes()));
        recalculateStatus(item);
        inventoryItemRepository.save(item);
        notifyLowStockIfNeeded(item);
        auditService.log(
            currentUser(principal),
            "INVENTORY_CONSUMED",
            "INVENTORY",
            item.getId().toString(),
            "Consumed " + request.quantity() + " " + item.getResource().getUnit()
        );
        return InventoryItemResponse.from(item);
    }

    @Transactional
    public InventoryItemResponse updateStorage(UserPrincipal principal, InventoryAdjustRequest request) {
        InventoryItem item = findOwnedInventory(principal, request.inventoryItemId());
        item.setBranchName(trimToNull(request.branchName()));
        item.setStorageLocation(trimToNull(request.storageLocation()));
        item.setNotes(trimToNull(request.notes()));
        inventoryItemRepository.save(item);
        auditService.log(currentUser(principal), "INVENTORY_STORAGE_UPDATED", "INVENTORY", item.getId().toString(), "Updated inventory storage");
        return InventoryItemResponse.from(item);
    }

    @Transactional
    @Scheduled(fixedDelayString = "${app.scheduler.expiry-check-ms}")
    public void markExpiredInventory() {
        List<InventoryItem> items = inventoryItemRepository.findAll();
        boolean updated = false;
        for (InventoryItem item : items) {
            if (item.getStatus() == InventoryStatus.EXPIRED || item.getQuantityAvailable() <= 0) {
                continue;
            }
            if (isResourceExpired(item.getResource())) {
                item.setQuantityExpired(item.getQuantityExpired() + item.getQuantityAvailable());
                item.setQuantityAvailable(0);
                item.setStatus(InventoryStatus.EXPIRED);
                updated = true;
                notificationService.notifyUser(
                    item.getReceiver(),
                    NotificationType.RESOURCE_EXPIRING_SOON,
                    "Inventory item expired",
                    item.getResource().getTitle() + " expired in inventory and was removed from available stock"
                );
                auditService.log(null, "INVENTORY_EXPIRED", "INVENTORY", item.getId().toString(), "Inventory expired automatically");
            } else {
                recalculateStatus(item);
            }
        }
        if (updated) {
            inventoryItemRepository.saveAll(items);
        }
    }

    private InventoryItem findOwnedInventory(UserPrincipal principal, UUID inventoryItemId) {
        User user = currentUser(principal);
        InventoryItem item = inventoryItemRepository.findById(inventoryItemId)
            .orElseThrow(() -> new NotFoundException("Inventory item not found"));
        if (user.getRole() != Role.ADMIN && !item.getReceiver().getId().equals(user.getId())) {
            throw new ForbiddenException("This inventory item does not belong to your organization");
        }
        return item;
    }

    private User currentUser(UserPrincipal principal) {
        return userRepository.findById(principal.getId())
            .orElseThrow(() -> new NotFoundException("User not found"));
    }

    private void recalculateStatus(InventoryItem item) {
        if (isResourceExpired(item.getResource())) {
            item.setStatus(InventoryStatus.EXPIRED);
            return;
        }
        if (item.getQuantityAvailable() <= 0) {
            item.setStatus(InventoryStatus.DEPLETED);
            return;
        }
        if (item.getQuantityAvailable() <= Math.max(1, item.getQuantityReceived() / 4)) {
            item.setStatus(InventoryStatus.LOW_STOCK);
            return;
        }
        item.setStatus(InventoryStatus.ACTIVE);
    }

    private void notifyLowStockIfNeeded(InventoryItem item) {
        if (item.getStatus() == InventoryStatus.LOW_STOCK) {
            notificationService.notifyUser(
                item.getReceiver(),
                NotificationType.INVENTORY_LOW_STOCK,
                "Inventory running low",
                item.getResource().getTitle() + " is running low in inventory"
            );
        }
    }

    private boolean isResourceExpired(Resource resource) {
        if (resource.getExpiresAt() != null) {
            return resource.getExpiresAt().isBefore(java.time.LocalDateTime.now());
        }
        return resource.getMedicineExpiryDate() != null && resource.getMedicineExpiryDate().isBefore(LocalDate.now(ZoneOffset.UTC));
    }

    private String trimToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }
}

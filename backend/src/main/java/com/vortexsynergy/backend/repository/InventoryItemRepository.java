package com.vortexsynergy.backend.repository;

import com.vortexsynergy.backend.model.InventoryItem;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InventoryItemRepository extends JpaRepository<InventoryItem, UUID> {

    List<InventoryItem> findByReceiverIdOrderByCreatedAtDesc(UUID receiverId);

    Optional<InventoryItem> findByClaimId(UUID claimId);
}

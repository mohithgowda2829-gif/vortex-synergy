package com.vortexsynergy.backend.model;

import com.vortexsynergy.backend.model.enums.InventoryStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(
    name = "inventory_items",
    indexes = {
        @Index(name = "idx_inventory_receiver_status", columnList = "receiver_id, status"),
        @Index(name = "idx_inventory_resource", columnList = "resource_id")
    }
)
public class InventoryItem extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "receiver_id", nullable = false)
    private User receiver;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "resource_id", nullable = false)
    private Resource resource;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "claim_id")
    private Claim claim;

    @Column(nullable = false)
    private Integer quantityReceived;

    @Column(nullable = false)
    private Integer quantityAvailable;

    @Column(nullable = false)
    private Integer quantityConsumed;

    @Column(nullable = false)
    private Integer quantityExpired;

    @Column(length = 120)
    private String branchName;

    @Column(length = 255)
    private String storageLocation;

    private Instant stockedAt;

    private Instant lastConsumedAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private InventoryStatus status;

    @Column(length = 1000)
    private String notes;
}

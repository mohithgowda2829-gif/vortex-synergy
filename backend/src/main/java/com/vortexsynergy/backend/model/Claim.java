package com.vortexsynergy.backend.model;

import com.vortexsynergy.backend.model.enums.ClaimStatus;
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
    name = "claims",
    indexes = {
        @Index(name = "idx_claims_receiver_status", columnList = "receiver_id, status"),
        @Index(name = "idx_claims_resource_status", columnList = "resource_id, status")
    }
)
public class Claim extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "resource_id", nullable = false)
    private Resource resource;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "receiver_id", nullable = false)
    private User receiver;

    @Column(nullable = false)
    private Integer quantity;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ClaimStatus status;

    @Column(nullable = false)
    private String pickupCode;

    @Column(nullable = false)
    private Instant reservedAt;

    @Column(nullable = false)
    private Instant reservationExpiresAt;

    private Instant confirmedAt;

    private Instant claimedAt;

    private Instant cancelledAt;

    private String cancellationReason;

    @Column(nullable = false)
    private boolean deliveryRequested;

    private Integer priorityScore;

    @Column(length = 1000)
    private String priorityExplanation;

    @Column(length = 120)
    private String pickupPersonName;

    @Column(length = 20)
    private String pickupPersonPhone;

    @Column(length = 32)
    private String pickupVehicleNumber;

    @Column(length = 120)
    private String pickupVehicleDetails;

    private Instant pickupDetailsSubmittedAt;

    private Boolean pickupDetailsApproved;

    private Instant pickupDetailsApprovedAt;

    @Column(nullable = false)
    private boolean pickupConfirmedByReceiver;

    @Column(nullable = false)
    private boolean handoverConfirmed;
}

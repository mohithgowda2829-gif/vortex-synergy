package com.vortexsynergy.backend.model;

import com.vortexsynergy.backend.model.enums.DeliveryStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
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
    name = "deliveries",
    indexes = {
        @Index(name = "idx_deliveries_receiver_status", columnList = "receiver_id, status"),
        @Index(name = "idx_deliveries_status_created_at", columnList = "status, created_at")
    }
)
public class Delivery extends BaseEntity {

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "claim_id", nullable = false, unique = true)
    private Claim claim;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "receiver_id")
    private User receiver;

    @Column(length = 64)
    private String orderNumber;

    @Column(length = 32)
    private String vehicleNumber;

    @Column(length = 120)
    private String agentName;

    @Column(length = 20)
    private String agentMobile;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DeliveryStatus status;

    private Instant pickupApprovedAt;

    private Instant deliveredAt;

    private Instant receiverConfirmedAt;

    @Column(length = 1000)
    private String failedReason;

    private Double lastLatitude;

    private Double lastLongitude;

    private Instant lastLocationUpdateAt;

    @Column(length = 1000)
    private String notes;
}

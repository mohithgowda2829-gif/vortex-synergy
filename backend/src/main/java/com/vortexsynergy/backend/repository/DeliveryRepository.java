package com.vortexsynergy.backend.repository;

import com.vortexsynergy.backend.dto.report.DeliveryReportRow;
import com.vortexsynergy.backend.model.Delivery;
import com.vortexsynergy.backend.model.enums.DeliveryStatus;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface DeliveryRepository extends JpaRepository<Delivery, UUID> {

    List<Delivery> findByStatusInOrderByCreatedAtAsc(Collection<DeliveryStatus> statuses);

    List<Delivery> findByReceiverIdOrderByCreatedAtDesc(UUID receiverId);

    List<Delivery> findByClaimResourceDonorIdOrderByCreatedAtDesc(UUID donorId);

    Optional<Delivery> findByClaimId(UUID claimId);

    long countByReceiverIdAndStatusIn(UUID receiverId, Collection<DeliveryStatus> statuses);

    long countByClaimResourceDonorIdAndStatusIn(UUID donorId, Collection<DeliveryStatus> statuses);

    long countByStatusIn(Collection<DeliveryStatus> statuses);

    long countByReceiverIdAndStatus(UUID receiverId, DeliveryStatus status);

    @Query("""
        select new com.vortexsynergy.backend.dto.report.DeliveryReportRow(
            d.id,
            claim.id,
            resource.title,
            receiver.fullName,
            d.orderNumber,
            d.agentName,
            d.agentMobile,
            d.vehicleNumber,
            d.status,
            d.pickupApprovedAt,
            d.deliveredAt,
            d.failedReason
        )
        from Delivery d
        join d.claim claim
        join claim.resource resource
        join claim.receiver receiver
        order by d.createdAt desc
        """)
    List<DeliveryReportRow> findDeliveryReportRowsForAdmin();

    @Query("""
        select new com.vortexsynergy.backend.dto.report.DeliveryReportRow(
            d.id,
            claim.id,
            resource.title,
            receiver.fullName,
            d.orderNumber,
            d.agentName,
            d.agentMobile,
            d.vehicleNumber,
            d.status,
            d.pickupApprovedAt,
            d.deliveredAt,
            d.failedReason
        )
        from Delivery d
        join d.claim claim
        join claim.resource resource
        join claim.receiver receiver
        where receiver.id = :receiverId
        order by d.createdAt desc
        """)
    List<DeliveryReportRow> findDeliveryReportRowsForReceiver(@Param("receiverId") UUID receiverId);
}

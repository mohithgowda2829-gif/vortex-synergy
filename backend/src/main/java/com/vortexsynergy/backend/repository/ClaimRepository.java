package com.vortexsynergy.backend.repository;

import com.vortexsynergy.backend.dto.report.ClaimReportRow;
import com.vortexsynergy.backend.dto.report.DonationReportRow;
import com.vortexsynergy.backend.model.Claim;
import com.vortexsynergy.backend.model.enums.ClaimStatus;
import com.vortexsynergy.backend.model.enums.ResourceType;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ClaimRepository extends JpaRepository<Claim, UUID> {

    List<Claim> findByReceiverIdOrderByCreatedAtDesc(UUID receiverId);

    List<Claim> findByResourceDonorIdOrderByCreatedAtDesc(UUID donorId);

    List<Claim> findByResourceIdOrderByCreatedAtAsc(UUID resourceId);

    boolean existsByReceiverIdAndResourceIdAndStatusIn(
        UUID receiverId,
        UUID resourceId,
        Collection<ClaimStatus> statuses
    );

    List<Claim> findByStatusAndReservationExpiresAtBefore(ClaimStatus status, Instant cutoff);

    long countByStatus(ClaimStatus status);

    long countByReceiverIdAndStatus(UUID receiverId, ClaimStatus status);

    long countByReceiverIdAndStatusIn(UUID receiverId, Collection<ClaimStatus> statuses);

    long countByResourceDonorIdAndStatus(UUID donorId, ClaimStatus status);

    long countByResourceDonorIdAndStatusIn(UUID donorId, Collection<ClaimStatus> statuses);

    @Query("""
        select coalesce(sum(c.quantity), 0) from Claim c
        where c.status = com.vortexsynergy.backend.model.enums.ClaimStatus.CLAIMED
          and c.resource.resourceType = :resourceType
        """)
    long sumClaimedQuantityByType(@Param("resourceType") ResourceType resourceType);

    @Query("""
        select count(distinct c.resource.id) from Claim c
        where c.status = com.vortexsynergy.backend.model.enums.ClaimStatus.CLAIMED
          and c.resource.donor.id = :donorId
        """)
    long countCompletedContributionsByDonor(@Param("donorId") UUID donorId);

    @Query("""
        select coalesce(sum(c.quantity), 0) from Claim c
        where c.status = com.vortexsynergy.backend.model.enums.ClaimStatus.CLAIMED
          and c.resource.donor.id = :donorId
        """)
    long sumImpactByDonor(@Param("donorId") UUID donorId);

    @Query("""
        select count(c) from Claim c
        where c.receiver.id = :receiverId
          and c.status in :statuses
          and c.createdAt >= :fromTime
        """)
    long countClaimsForReceiverSince(
        @Param("receiverId") UUID receiverId,
        @Param("statuses") Collection<ClaimStatus> statuses,
        @Param("fromTime") Instant fromTime
    );

    @Query("""
        select distinct new com.vortexsynergy.backend.dto.report.DonationReportRow(
            r.id,
            r.title,
            r.resourceType,
            d.fullName,
            r.status,
            r.city,
            r.area,
            r.quantity,
            r.availableQuantity,
            r.createdAt
        )
        from Claim c
        join c.resource r
        join r.donor d
        where c.receiver.id = :receiverId
        order by r.createdAt desc
        """)
    List<DonationReportRow> findDonationReportRowsForReceiver(@Param("receiverId") UUID receiverId);

    @Query("""
        select new com.vortexsynergy.backend.dto.report.ClaimReportRow(
            c.id,
            r.title,
            receiver.fullName,
            c.status,
            c.quantity,
            c.deliveryRequested,
            c.priorityScore,
            c.priorityExplanation,
            c.createdAt
        )
        from Claim c
        join c.resource r
        join c.receiver receiver
        order by c.createdAt desc
        """)
    List<ClaimReportRow> findClaimReportRowsForAdmin();

    @Query("""
        select new com.vortexsynergy.backend.dto.report.ClaimReportRow(
            c.id,
            r.title,
            receiver.fullName,
            c.status,
            c.quantity,
            c.deliveryRequested,
            c.priorityScore,
            c.priorityExplanation,
            c.createdAt
        )
        from Claim c
        join c.resource r
        join c.receiver receiver
        where receiver.id = :receiverId
        order by c.createdAt desc
        """)
    List<ClaimReportRow> findClaimReportRowsForReceiver(@Param("receiverId") UUID receiverId);
}

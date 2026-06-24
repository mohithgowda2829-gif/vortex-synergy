package com.vortexsynergy.backend.service;

import com.vortexsynergy.backend.dto.claim.ClaimCancelRequest;
import com.vortexsynergy.backend.dto.claim.ClaimConfirmRequest;
import com.vortexsynergy.backend.dto.claim.ClaimRequest;
import com.vortexsynergy.backend.dto.claim.ClaimResponse;
import com.vortexsynergy.backend.dto.claim.HandoverRequest;
import com.vortexsynergy.backend.dto.claim.PickupApprovalRequest;
import com.vortexsynergy.backend.dto.claim.PickupDetailsRequest;
import com.vortexsynergy.backend.exception.BadRequestException;
import com.vortexsynergy.backend.exception.ForbiddenException;
import com.vortexsynergy.backend.exception.NotFoundException;
import com.vortexsynergy.backend.model.Claim;
import com.vortexsynergy.backend.model.Delivery;
import com.vortexsynergy.backend.model.Resource;
import com.vortexsynergy.backend.model.User;
import com.vortexsynergy.backend.model.enums.ClaimStatus;
import com.vortexsynergy.backend.model.enums.DeliveryStatus;
import com.vortexsynergy.backend.model.enums.NotificationType;
import com.vortexsynergy.backend.model.enums.ResourceStatus;
import com.vortexsynergy.backend.model.enums.ResourceType;
import com.vortexsynergy.backend.model.enums.Role;
import com.vortexsynergy.backend.repository.ClaimRepository;
import com.vortexsynergy.backend.repository.DeliveryRepository;
import com.vortexsynergy.backend.repository.ResourceRepository;
import com.vortexsynergy.backend.repository.UserRepository;
import com.vortexsynergy.backend.security.UserPrincipal;
import jakarta.transaction.Transactional;
import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class ClaimService {

    private final ClaimRepository claimRepository;
    private final ResourceRepository resourceRepository;
    private final DeliveryRepository deliveryRepository;
    private final UserRepository userRepository;
    private final ResourceService resourceService;
    private final AuditService auditService;
    private final PriorityService priorityService;
    private final NotificationService notificationService;
    private final InventoryService inventoryService;

    @Value("${app.claim.reservation-hours}")
    private long reservationHours;

    @Transactional
    public ClaimResponse requestClaim(UserPrincipal principal, ClaimRequest request) {
        User receiver = currentUser(principal);
        if (receiver.getRole() != Role.RECEIVER) {
            throw new ForbiddenException("Only receivers can request claims");
        }

        Resource resource = resourceService.findResource(request.resourceId());
        if (!resourceService.isClaimable(resource)) {
            throw new BadRequestException("Resource is not available for claim");
        }
        if (request.quantity() > resource.getAvailableQuantity()) {
            throw new BadRequestException("Requested quantity exceeds available quantity");
        }
        if (receiver.getId().equals(resource.getDonor().getId())) {
            throw new BadRequestException("Donors cannot claim their own resources");
        }
        if (claimRepository.existsByReceiverIdAndResourceIdAndStatusIn(
            receiver.getId(),
            resource.getId(),
            Set.of(ClaimStatus.RESERVED)
        )) {
            throw new BadRequestException(
                "You already have an active reservation for this resource. Complete or cancel it before requesting again"
            );
        }

        PriorityService.PriorityResult priority = priorityService.calculate(
            resource,
            receiver,
            Boolean.TRUE.equals(request.urgentNeed()),
            Boolean.TRUE.equals(request.vulnerableReceiver())
        );

        String pickupCode = UUID.randomUUID().toString().substring(0, 8).toUpperCase(Locale.ROOT);
        Instant now = Instant.now();

        Claim claim = Claim.builder()
            .resource(resource)
            .receiver(receiver)
            .quantity(request.quantity())
            .status(ClaimStatus.RESERVED)
            .pickupCode(pickupCode)
            .reservedAt(now)
            .reservationExpiresAt(now.plusSeconds(reservationHours * 3600))
            .deliveryRequested(Boolean.TRUE.equals(request.deliveryRequested()) || resource.isRequiresReceiverDelivery())
            .priorityScore(priority.score())
            .priorityExplanation(priority.explanation())
            .pickupDetailsApproved(false)
            .pickupConfirmedByReceiver(false)
            .handoverConfirmed(false)
            .build();

        resource.setAvailableQuantity(resource.getAvailableQuantity() - request.quantity());
        resource.setStatus(resource.getAvailableQuantity() == 0 ? ResourceStatus.RESERVED : ResourceStatus.AVAILABLE);
        resourceRepository.save(resource);
        claimRepository.save(claim);

        auditService.log(
            receiver,
            "CLAIM_REQUESTED",
            "CLAIM",
            claim.getId().toString(),
            "Reserved resource " + resource.getId(),
            "{\"priorityScore\":" + priority.score() + ",\"priorityExplanation\":\"" + safeJson(priority.explanation()) + "\"}"
        );
        return ClaimResponse.from(claim, true);
    }

    @Transactional
    public ClaimResponse confirmClaim(UserPrincipal principal, ClaimConfirmRequest request) {
        User receiver = currentUser(principal);
        Claim claim = findClaim(request.claimId());
        ensureClaimOwner(receiver, claim);
        ensureReserved(claim);

        claim.setPickupConfirmedByReceiver(true);
        claim.setConfirmedAt(Instant.now());
        claimRepository.save(claim);

        notificationService.notifyUser(
            claim.getResource().getDonor(),
            NotificationType.CLAIM_ACCEPTED,
            "Claim confirmed",
            claim.getReceiver().getFullName() + " confirmed the reservation for " + claim.getResource().getTitle()
        );
        notificationService.notifyUser(
            claim.getReceiver(),
            NotificationType.CLAIM_ACCEPTED,
            "Claim active",
            "Your reservation for " + claim.getResource().getTitle() + " is active"
        );
        auditService.log(receiver, "CLAIM_CONFIRMED", "CLAIM", claim.getId().toString(), "Receiver confirmed reservation");
        return ClaimResponse.from(claim, true);
    }

    @Transactional
    public ClaimResponse cancelClaim(UserPrincipal principal, ClaimCancelRequest request) {
        User actor = currentUser(principal);
        Claim claim = findClaim(request.claimId());
        ensureReserved(claim);

        boolean authorized = actor.getRole() == Role.ADMIN
            || actor.getId().equals(claim.getReceiver().getId())
            || actor.getId().equals(claim.getResource().getDonor().getId());
        if (!authorized) {
            throw new ForbiddenException("You are not allowed to cancel this claim");
        }

        cancelReservedClaim(actor, claim, request.reason());

        if (actor.getRole() == Role.ADMIN || actor.getId().equals(claim.getResource().getDonor().getId())) {
            notificationService.notifyUser(
                claim.getReceiver(),
                NotificationType.CLAIM_REJECTED,
                "Claim cancelled",
                "Your claim for " + claim.getResource().getTitle() + " was cancelled"
            );
        }

        return ClaimResponse.from(claim, true);
    }

    @Transactional
    public ClaimResponse submitPickupDetails(UserPrincipal principal, PickupDetailsRequest request) {
        User receiver = currentUser(principal);
        if (receiver.getRole() != Role.RECEIVER) {
            throw new ForbiddenException("Only receivers can submit pickup representative details");
        }

        Claim claim = findClaim(request.claimId());
        ensureClaimOwner(receiver, claim);
        ensureReserved(claim);
        ensureDelegatedPickup(claim);

        claim.setPickupPersonName(normalize(request.pickupPersonName()));
        claim.setPickupPersonPhone(normalize(request.pickupPersonPhone()));
        claim.setPickupVehicleNumber(normalize(request.pickupVehicleNumber()));
        claim.setPickupVehicleDetails(normalize(request.pickupVehicleDetails()));
        claim.setPickupDetailsSubmittedAt(Instant.now());
        claim.setPickupDetailsApproved(false);
        claim.setPickupDetailsApprovedAt(null);
        claimRepository.save(claim);

        auditService.log(
            receiver,
            "CLAIM_PICKUP_DETAILS_SUBMITTED",
            "CLAIM",
            claim.getId().toString(),
            "Pickup person " + claim.getPickupPersonName() + " assigned for claim collection"
        );
        return ClaimResponse.from(claim, true);
    }

    @Transactional
    public ClaimResponse approvePickupDetails(UserPrincipal principal, PickupApprovalRequest request) {
        User actor = currentUser(principal);
        Claim claim = findClaim(request.claimId());
        ensureReserved(claim);
        ensureDelegatedPickup(claim);

        boolean authorized = actor.getRole() == Role.ADMIN
            || actor.getId().equals(claim.getResource().getDonor().getId());
        if (!authorized) {
            throw new ForbiddenException("Only the donor or admin can approve pickup representative details");
        }
        if (!hasPickupDetails(claim)) {
            throw new BadRequestException("Pickup representative details must be submitted before approval");
        }

        claim.setPickupDetailsApproved(true);
        claim.setPickupDetailsApprovedAt(Instant.now());
        claimRepository.save(claim);

        auditService.log(
            actor,
            "CLAIM_PICKUP_DETAILS_APPROVED",
            "CLAIM",
            claim.getId().toString(),
            "Approved pickup person " + claim.getPickupPersonName()
        );
        return ClaimResponse.from(claim, false);
    }

    @Transactional
    public ClaimResponse handoverClaim(UserPrincipal principal, HandoverRequest request) {
        User actor = currentUser(principal);
        Claim claim = findClaim(request.claimId());
        finalizeClaimWithPickupCode(actor, claim, request.pickupCode());

        auditService.log(actor, "CLAIM_HANDOVER_COMPLETED", "CLAIM", claim.getId().toString(), "Pickup code verified");
        return ClaimResponse.from(claim, actor.getRole() == Role.RECEIVER);
    }

    @Transactional
    public List<ClaimResponse> getMyClaims(UserPrincipal principal) {
        return claimRepository.findByReceiverIdOrderByCreatedAtDesc(principal.getId()).stream()
            .map(claim -> ClaimResponse.from(claim, true))
            .toList();
    }

    @Transactional
    public List<ClaimResponse> getDonorClaims(UserPrincipal principal) {
        return claimRepository.findByResourceDonorIdOrderByCreatedAtDesc(principal.getId()).stream()
            .map(claim -> ClaimResponse.from(claim, false))
            .toList();
    }

    public Claim findClaim(UUID claimId) {
        return claimRepository.findById(claimId)
            .orElseThrow(() -> new NotFoundException("Claim not found"));
    }

    @Transactional
    public void finalizeClaimWithPickupCode(User actor, Claim claim, String pickupCode) {
        ensureReserved(claim);
        if (claim.isDeliveryRequested()) {
            throw new BadRequestException("Receiver-managed delivery claims must use donor pickup approval instead of a pickup code");
        }
        if (!claim.getPickupCode().equalsIgnoreCase(pickupCode.trim())) {
            throw new BadRequestException("Pickup code is invalid");
        }

        boolean donorAuthorized = claim.getResource().getDonor().getId().equals(actor.getId());
        boolean adminAuthorized = actor.getRole() == Role.ADMIN;
        if (!donorAuthorized && !adminAuthorized) {
            throw new ForbiddenException("Only the donor or admin can complete self-pickup handover");
        }

        completeClaim(actor, claim, "Self-pickup handover completed");
    }

    @Transactional
    public void completeClaimAfterDelivery(User actor, Claim claim, String note) {
        ensureReserved(claim);
        claim.setHandoverConfirmed(true);
        completeClaim(actor, claim, note);
    }

    @Transactional
    public void failDeliveryClaim(User actor, Claim claim, String reason) {
        ensureReserved(claim);
        cancelReservedClaim(actor, claim, "Delivery failed: " + reason);
    }

    @Transactional
    @Scheduled(fixedDelayString = "${app.scheduler.expiry-check-ms}")
    public void expireStaleReservations() {
        List<Claim> expiredClaims = claimRepository.findByStatusAndReservationExpiresAtBefore(ClaimStatus.RESERVED, Instant.now());
        for (Claim claim : expiredClaims) {
            claim.setStatus(ClaimStatus.EXPIRED);
            claimRepository.save(claim);
            restoreResourceQuantity(claim);
            deliveryRepository.findByClaimId(claim.getId()).ifPresent(delivery -> {
                delivery.setStatus(DeliveryStatus.CANCELLED);
                delivery.setNotes("Cancelled after reservation expiry");
                deliveryRepository.save(delivery);
            });
            auditService.log(null, "CLAIM_EXPIRED", "CLAIM", claim.getId().toString(), "Reservation expired automatically");
        }
    }

    private void cancelReservedClaim(User actor, Claim claim, String reason) {
        claim.setStatus(ClaimStatus.CANCELLED);
        claim.setCancelledAt(Instant.now());
        claim.setCancellationReason(reason);
        claimRepository.save(claim);

        restoreResourceQuantity(claim);
        deliveryRepository.findByClaimId(claim.getId()).ifPresent(delivery -> {
            delivery.setStatus(DeliveryStatus.CANCELLED);
            delivery.setNotes(reason);
            deliveryRepository.save(delivery);
        });

        auditService.log(actor, "CLAIM_CANCELLED", "CLAIM", claim.getId().toString(), reason);
    }

    private void completeClaim(User actor, Claim claim, String note) {
        claim.setStatus(ClaimStatus.CLAIMED);
        claim.setClaimedAt(Instant.now());
        claim.setHandoverConfirmed(true);
        claimRepository.save(claim);

        Resource resource = claim.getResource();
        resource.setStatus(resource.getAvailableQuantity() > 0 ? ResourceStatus.AVAILABLE : ResourceStatus.CLAIMED);
        resourceRepository.save(resource);
        inventoryService.stockClaim(claim);

        auditService.log(actor, "CLAIM_COMPLETED", "CLAIM", claim.getId().toString(), note);
    }

    private void restoreResourceQuantity(Claim claim) {
        Resource resource = claim.getResource();
        if (resource.getStatus() != ResourceStatus.EXPIRED && resource.getStatus() != ResourceStatus.CANCELLED) {
            resource.setAvailableQuantity(resource.getAvailableQuantity() + claim.getQuantity());
            resource.setStatus(ResourceStatus.AVAILABLE);
            resourceRepository.save(resource);
        }
    }

    private void ensureClaimOwner(User receiver, Claim claim) {
        if (!claim.getReceiver().getId().equals(receiver.getId())) {
            throw new ForbiddenException("This claim does not belong to you");
        }
    }

    private void ensureReserved(Claim claim) {
        if (claim.getStatus() != ClaimStatus.RESERVED) {
            throw new BadRequestException("Claim is not in reserved state");
        }
    }

    private void ensureDelegatedPickup(Claim claim) {
        if (!claim.isDeliveryRequested()) {
            throw new BadRequestException("This claim is configured for self pickup");
        }
    }

    private boolean hasPickupDetails(Claim claim) {
        return claim.getPickupPersonName() != null && !claim.getPickupPersonName().isBlank()
            && claim.getPickupPersonPhone() != null && !claim.getPickupPersonPhone().isBlank()
            && claim.getPickupVehicleNumber() != null && !claim.getPickupVehicleNumber().isBlank()
            && claim.getPickupVehicleDetails() != null && !claim.getPickupVehicleDetails().isBlank();
    }

    private String normalize(String value) {
        return value == null ? null : value.trim();
    }

    private String safeJson(String value) {
        return value == null ? "" : value.replace("\"", "\\\"");
    }

    private User currentUser(UserPrincipal principal) {
        return userRepository.findById(principal.getId())
            .orElseThrow(() -> new NotFoundException("User not found"));
    }
}

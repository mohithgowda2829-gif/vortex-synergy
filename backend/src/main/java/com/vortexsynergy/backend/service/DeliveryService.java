package com.vortexsynergy.backend.service;

import com.vortexsynergy.backend.dto.delivery.DeliveryAssignRequest;
import com.vortexsynergy.backend.dto.delivery.DeliveryFailRequest;
import com.vortexsynergy.backend.dto.delivery.DeliveryResponse;
import com.vortexsynergy.backend.dto.delivery.DeliveryStatusUpdateRequest;
import com.vortexsynergy.backend.exception.BadRequestException;
import com.vortexsynergy.backend.exception.ForbiddenException;
import com.vortexsynergy.backend.exception.NotFoundException;
import com.vortexsynergy.backend.model.Claim;
import com.vortexsynergy.backend.model.Delivery;
import com.vortexsynergy.backend.model.User;
import com.vortexsynergy.backend.model.enums.DeliveryStatus;
import com.vortexsynergy.backend.model.enums.NotificationType;
import com.vortexsynergy.backend.model.enums.Role;
import com.vortexsynergy.backend.repository.DeliveryRepository;
import com.vortexsynergy.backend.repository.UserRepository;
import com.vortexsynergy.backend.security.UserPrincipal;
import jakarta.transaction.Transactional;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class DeliveryService {

    private final DeliveryRepository deliveryRepository;
    private final UserRepository userRepository;
    private final ClaimService claimService;
    private final AuditService auditService;
    private final NotificationService notificationService;

    @Transactional
    public DeliveryResponse assignDelivery(UserPrincipal principal, DeliveryAssignRequest request) {
        User receiver = currentUser(principal);
        if (receiver.getRole() != Role.RECEIVER && receiver.getRole() != Role.ADMIN) {
            throw new ForbiddenException("Only receiver organizations or admins can assign delivery agents");
        }

        Claim claim = claimService.findClaim(request.claimId());
        ensureReceiverAccess(receiver, claim);
        ensureDeliverableClaim(claim);
        if (!claim.isPickupConfirmedByReceiver()) {
            throw new BadRequestException("Claim must be confirmed before assigning a delivery agent");
        }
        ensureCoordinatePair(request.lastLatitude(), request.lastLongitude());

        Delivery delivery = deliveryRepository.findByClaimId(claim.getId())
            .orElseGet(() -> Delivery.builder()
                .claim(claim)
                .receiver(claim.getReceiver())
                .status(DeliveryStatus.ASSIGNED)
                .build());

        delivery.setReceiver(claim.getReceiver());
        delivery.setOrderNumber(request.orderNumber().trim());
        delivery.setVehicleNumber(request.vehicleNumber().trim());
        delivery.setAgentName(request.agentName().trim());
        delivery.setAgentMobile(request.agentMobile().trim());
        delivery.setNotes(trimToNull(request.notes()));
        applyLocation(delivery, request.lastLatitude(), request.lastLongitude());
        // V1 records may still carry legacy delivery states. Reassignment should
        // move any non-terminal legacy row into the V2 assignment lifecycle.
        if (delivery.getStatus() == null
            || delivery.getStatus() == DeliveryStatus.OPEN
            || delivery.getStatus() == DeliveryStatus.ACCEPTED
            || delivery.getStatus() == DeliveryStatus.CANCELLED
            || delivery.getStatus() == DeliveryStatus.FAILED) {
            delivery.setStatus(DeliveryStatus.ASSIGNED);
        }

        deliveryRepository.save(delivery);
        notificationService.notifyUser(
            claim.getResource().getDonor(),
            NotificationType.DELIVERY_ASSIGNED,
            "Delivery agent assigned",
            request.agentName().trim() + " was assigned for " + claim.getResource().getTitle()
        );
        notificationService.notifyUser(
            claim.getReceiver(),
            NotificationType.DELIVERY_ASSIGNED,
            "Delivery agent assigned",
            "Order " + request.orderNumber().trim() + " is now assigned to collect " + claim.getResource().getTitle()
        );
        auditService.log(
            receiver,
            "DELIVERY_ASSIGNED",
            "CLAIM",
            claim.getId().toString(),
            "Delivery agent assigned",
            "{\"orderNumber\":\"" + safeJson(delivery.getOrderNumber()) + "\",\"agentName\":\"" + safeJson(delivery.getAgentName()) + "\"}"
        );
        return DeliveryResponse.from(delivery);
    }

    @Transactional
    public DeliveryResponse getByClaim(UserPrincipal principal, UUID claimId) {
        Claim claim = claimService.findClaim(claimId);
        ensureDeliveryAccess(currentUser(principal), claim);
        return deliveryRepository.findByClaimId(claimId)
            .map(DeliveryResponse::from)
            .orElseThrow(() -> new NotFoundException("Delivery not found for this claim"));
    }

    @Transactional
    public DeliveryResponse pickupApprove(UserPrincipal principal, DeliveryStatusUpdateRequest request) {
        User donor = currentUser(principal);
        Delivery delivery = deliveryRepository.findByClaimId(request.claimId())
            .orElseThrow(() -> new NotFoundException("Delivery not found"));
        Claim claim = delivery.getClaim();
        ensureCoordinatePair(request.latitude(), request.longitude());

        boolean authorized = donor.getRole() == Role.ADMIN || claim.getResource().getDonor().getId().equals(donor.getId());
        if (!authorized) {
            throw new ForbiddenException("Only the donor or admin can approve pickup");
        }
        String pickupCode = trimToNull(request.pickupCode());
        if (pickupCode == null) {
            throw new BadRequestException("Receiver pickup code is required before approving delivery pickup");
        }
        if (claim.getPickupCode() == null || !claim.getPickupCode().equalsIgnoreCase(pickupCode)) {
            throw new BadRequestException("Pickup code is invalid");
        }
        if (delivery.getStatus() == DeliveryStatus.PICKUP_APPROVED
            || delivery.getStatus() == DeliveryStatus.IN_TRANSIT
            || delivery.getStatus() == DeliveryStatus.DELIVERED) {
            throw new BadRequestException("Pickup has already been approved for this delivery");
        }
        ensureDeliveryStatus(delivery, DeliveryStatus.ASSIGNED, DeliveryStatus.PICKUP_PENDING);

        delivery.setStatus(DeliveryStatus.PICKUP_APPROVED);
        delivery.setPickupApprovedAt(Instant.now());
        applyLocation(delivery, request.latitude(), request.longitude());
        if (request.note() != null && !request.note().isBlank()) {
            delivery.setNotes(request.note().trim());
        }
        deliveryRepository.save(delivery);

        notificationService.notifyUser(
            claim.getReceiver(),
            NotificationType.PICKUP_APPROVED,
            "Pickup approved",
            "The donor approved pickup for order " + delivery.getOrderNumber()
        );
        auditService.log(
            donor,
            "DELIVERY_PICKUP_APPROVED",
            "CLAIM",
            claim.getId().toString(),
            "Donor approved pickup",
            "{\"orderNumber\":\"" + safeJson(delivery.getOrderNumber()) + "\",\"pickupCodeVerified\":true}"
        );
        return DeliveryResponse.from(delivery);
    }

    @Transactional
    public DeliveryResponse markInTransit(UserPrincipal principal, DeliveryStatusUpdateRequest request) {
        User receiver = currentUser(principal);
        Delivery delivery = deliveryRepository.findByClaimId(request.claimId())
            .orElseThrow(() -> new NotFoundException("Delivery not found"));
        ensureReceiverAccess(receiver, delivery.getClaim());
        ensureCoordinatePair(request.latitude(), request.longitude());
        ensureDeliveryStatus(delivery, DeliveryStatus.PICKUP_APPROVED, DeliveryStatus.IN_TRANSIT);

        delivery.setStatus(DeliveryStatus.IN_TRANSIT);
        if (request.note() != null && !request.note().isBlank()) {
            delivery.setNotes(request.note().trim());
        }
        applyLocation(delivery, request.latitude(), request.longitude());
        deliveryRepository.save(delivery);

        auditService.log(receiver, "DELIVERY_IN_TRANSIT", "CLAIM", delivery.getClaim().getId().toString(), "Delivery moved in transit");
        return DeliveryResponse.from(delivery);
    }

    @Transactional
    public DeliveryResponse markDelivered(UserPrincipal principal, DeliveryStatusUpdateRequest request) {
        User receiver = currentUser(principal);
        Delivery delivery = deliveryRepository.findByClaimId(request.claimId())
            .orElseThrow(() -> new NotFoundException("Delivery not found"));
        ensureReceiverAccess(receiver, delivery.getClaim());
        ensureCoordinatePair(request.latitude(), request.longitude());
        ensureDeliveryStatus(delivery, DeliveryStatus.PICKUP_APPROVED, DeliveryStatus.IN_TRANSIT);

        delivery.setStatus(DeliveryStatus.DELIVERED);
        delivery.setDeliveredAt(Instant.now());
        if (request.note() != null && !request.note().isBlank()) {
            delivery.setNotes(request.note().trim());
        }
        applyLocation(delivery, request.latitude(), request.longitude());
        deliveryRepository.save(delivery);

        claimService.completeClaimAfterDelivery(receiver, delivery.getClaim(), "Delivery completed by receiver organization");
        notificationService.notifyUser(
            delivery.getClaim().getResource().getDonor(),
            NotificationType.DELIVERY_COMPLETED,
            "Delivery completed",
            "Order " + delivery.getOrderNumber() + " was delivered successfully"
        );
        notificationService.notifyUser(
            delivery.getClaim().getReceiver(),
            NotificationType.DELIVERY_COMPLETED,
            "Delivery completed",
            "Order " + delivery.getOrderNumber() + " reached the receiver"
        );
        auditService.log(receiver, "DELIVERY_COMPLETED", "CLAIM", delivery.getClaim().getId().toString(), "Delivery completed");
        return DeliveryResponse.from(delivery);
    }

    @Transactional
    public DeliveryResponse confirmReceipt(UserPrincipal principal, DeliveryStatusUpdateRequest request) {
        User receiver = currentUser(principal);
        Delivery delivery = deliveryRepository.findByClaimId(request.claimId())
            .orElseThrow(() -> new NotFoundException("Delivery not found"));
        ensureReceiverAccess(receiver, delivery.getClaim());
        ensureCoordinatePair(request.latitude(), request.longitude());

        if (delivery.getStatus() != DeliveryStatus.DELIVERED) {
            throw new BadRequestException("Only delivered resources can be receipt-confirmed");
        }
        if (delivery.getReceiverConfirmedAt() != null) {
            throw new BadRequestException("Final receipt has already been confirmed");
        }

        delivery.setReceiverConfirmedAt(Instant.now());
        if (request.note() != null && !request.note().isBlank()) {
            delivery.setNotes(request.note().trim());
        }
        applyLocation(delivery, request.latitude(), request.longitude());
        deliveryRepository.save(delivery);

        notificationService.notifyUser(
            delivery.getClaim().getResource().getDonor(),
            NotificationType.DELIVERY_COMPLETED,
            "Receipt confirmed",
            "The receiver confirmed final receipt for order " + delivery.getOrderNumber()
        );
        auditService.log(receiver, "DELIVERY_RECEIPT_CONFIRMED", "CLAIM", delivery.getClaim().getId().toString(), "Receiver confirmed final receipt");
        return DeliveryResponse.from(delivery);
    }

    @Transactional
    public DeliveryResponse failDelivery(UserPrincipal principal, DeliveryFailRequest request) {
        User receiver = currentUser(principal);
        Delivery delivery = deliveryRepository.findByClaimId(request.claimId())
            .orElseThrow(() -> new NotFoundException("Delivery not found"));
        ensureReceiverAccess(receiver, delivery.getClaim());
        ensureDeliveryStatus(
            delivery,
            DeliveryStatus.ASSIGNED,
            DeliveryStatus.PICKUP_PENDING,
            DeliveryStatus.PICKUP_APPROVED,
            DeliveryStatus.IN_TRANSIT
        );

        delivery.setStatus(DeliveryStatus.FAILED);
        delivery.setFailedReason(request.failedReason().trim());
        deliveryRepository.save(delivery);

        claimService.failDeliveryClaim(receiver, delivery.getClaim(), request.failedReason().trim());
        notificationService.notifyUser(
            delivery.getClaim().getResource().getDonor(),
            NotificationType.DELIVERY_FAILED,
            "Delivery failed",
            "Order " + delivery.getOrderNumber() + " failed: " + request.failedReason().trim()
        );
        notificationService.notifyUser(
            delivery.getClaim().getReceiver(),
            NotificationType.DELIVERY_FAILED,
            "Delivery failed",
            "Order " + delivery.getOrderNumber() + " failed and the claim was cancelled"
        );
        auditService.log(receiver, "DELIVERY_FAILED", "CLAIM", delivery.getClaim().getId().toString(), request.failedReason().trim());
        return DeliveryResponse.from(delivery);
    }

    @Transactional
    public List<DeliveryResponse> getReceiverDeliveries(UserPrincipal principal) {
        User receiver = currentUser(principal);
        if (receiver.getRole() != Role.RECEIVER && receiver.getRole() != Role.ADMIN) {
            throw new ForbiddenException("Only receivers or admins can view receiver deliveries");
        }
        if (receiver.getRole() == Role.ADMIN) {
            return deliveryRepository.findAll().stream().map(DeliveryResponse::from).toList();
        }
        return deliveryRepository.findByReceiverIdOrderByCreatedAtDesc(receiver.getId()).stream()
            .map(DeliveryResponse::from)
            .toList();
    }

    @Transactional
    public List<DeliveryResponse> getDonorDeliveries(UserPrincipal principal) {
        User donor = currentUser(principal);
        if (donor.getRole() != Role.DONOR && donor.getRole() != Role.ADMIN) {
            throw new ForbiddenException("Only donors or admins can view donor delivery progress");
        }
        if (donor.getRole() == Role.ADMIN) {
            return deliveryRepository.findAll().stream().map(DeliveryResponse::from).toList();
        }
        return deliveryRepository.findByClaimResourceDonorIdOrderByCreatedAtDesc(donor.getId()).stream()
            .map(DeliveryResponse::from)
            .toList();
    }

    private void ensureDeliverableClaim(Claim claim) {
        if (!claim.isDeliveryRequested()) {
            throw new BadRequestException("This claim is configured for self pickup");
        }
        if (claim.getStatus() != com.vortexsynergy.backend.model.enums.ClaimStatus.RESERVED) {
            throw new BadRequestException("Only reserved claims can receive a delivery assignment");
        }
    }

    private void ensureReceiverAccess(User actor, Claim claim) {
        boolean allowed = actor.getRole() == Role.ADMIN
            || actor.getId().equals(claim.getReceiver().getId());
        if (!allowed) {
            throw new ForbiddenException("Only the receiver organization or admin can manage this delivery");
        }
    }

    private void ensureDeliveryAccess(User actor, Claim claim) {
        boolean allowed = actor.getRole() == Role.ADMIN
            || actor.getId().equals(claim.getReceiver().getId())
            || actor.getId().equals(claim.getResource().getDonor().getId());
        if (!allowed) {
            throw new ForbiddenException("You do not have access to this delivery");
        }
    }

    private void ensureDeliveryStatus(Delivery delivery, DeliveryStatus... allowedStatuses) {
        for (DeliveryStatus allowedStatus : allowedStatuses) {
            if (delivery.getStatus() == allowedStatus) {
                return;
            }
        }
        throw new BadRequestException("Delivery is not in a valid state for this transition");
    }

    private void applyLocation(Delivery delivery, Double latitude, Double longitude) {
        if (latitude != null) {
            delivery.setLastLatitude(latitude);
        }
        if (longitude != null) {
            delivery.setLastLongitude(longitude);
        }
        if (latitude != null || longitude != null) {
            delivery.setLastLocationUpdateAt(Instant.now());
        }
    }

    private void ensureCoordinatePair(Double latitude, Double longitude) {
        if ((latitude == null) != (longitude == null)) {
            throw new BadRequestException("Latitude and longitude must be provided together");
        }
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private String safeJson(String value) {
        return value == null ? "" : value.replace("\"", "\\\"");
    }

    private User currentUser(UserPrincipal principal) {
        return userRepository.findById(principal.getId())
            .orElseThrow(() -> new NotFoundException("User not found"));
    }
}

package com.vortexsynergy.backend.service;

import com.vortexsynergy.backend.dto.dashboard.DashboardSummaryResponse;
import com.vortexsynergy.backend.dto.dashboard.DonorCertificateDetailResponse;
import com.vortexsynergy.backend.dto.dashboard.DonorCertificateResponse;
import com.vortexsynergy.backend.dto.dashboard.RoleDashboardResponse;
import com.vortexsynergy.backend.exception.NotFoundException;
import com.vortexsynergy.backend.model.Verification;
import com.vortexsynergy.backend.model.enums.ClaimStatus;
import com.vortexsynergy.backend.model.enums.DeliveryStatus;
import com.vortexsynergy.backend.model.enums.ResourceStatus;
import com.vortexsynergy.backend.model.enums.ResourceType;
import com.vortexsynergy.backend.model.enums.Role;
import com.vortexsynergy.backend.model.enums.VerificationStatus;
import com.vortexsynergy.backend.model.enums.VerificationType;
import com.vortexsynergy.backend.repository.UserRepository;
import com.vortexsynergy.backend.repository.ClaimRepository;
import com.vortexsynergy.backend.repository.DeliveryRepository;
import com.vortexsynergy.backend.repository.NotificationRepository;
import com.vortexsynergy.backend.repository.ResourceRepository;
import com.vortexsynergy.backend.repository.VerificationRepository;
import com.vortexsynergy.backend.security.UserPrincipal;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final ClaimRepository claimRepository;
    private final UserRepository userRepository;
    private final ResourceRepository resourceRepository;
    private final DeliveryRepository deliveryRepository;
    private final NotificationRepository notificationRepository;
    private final VerificationRepository verificationRepository;

    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    public DashboardSummaryResponse getSummary() {
        return new DashboardSummaryResponse(
            claimRepository.sumClaimedQuantityByType(ResourceType.FOOD),
            claimRepository.sumClaimedQuantityByType(ResourceType.MEDICINE),
            userRepository.countByRole(Role.DONOR),
            claimRepository.countByStatus(ClaimStatus.CLAIMED),
            resourceRepository.countByStatus(ResourceStatus.EXPIRED)
        );
    }

    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    public DonorCertificateResponse getDonorCertificate(UserPrincipal principal) {
        var donor = userRepository.findById(principal.getId())
            .orElseThrow(() -> new NotFoundException("User not found"));

        return new DonorCertificateResponse(
            donor.getFullName(),
            claimRepository.countCompletedContributionsByDonor(donor.getId()),
            claimRepository.sumImpactByDonor(donor.getId())
        );
    }

    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    public DonorCertificateDetailResponse getDonorCertificateDetail(UserPrincipal principal) {
        var donor = userRepository.findById(principal.getId())
            .orElseThrow(() -> new NotFoundException("User not found"));

        long contributions = claimRepository.countCompletedContributionsByDonor(donor.getId());
        long impact = claimRepository.sumImpactByDonor(donor.getId());
        Instant issuedAt = Instant.now();

        return new DonorCertificateDetailResponse(
            donor.getFullName(),
            contributions,
            impact,
            buildCertificateNumber(donor.getId().toString(), issuedAt),
            issuedAt,
            "Vortex Synergy",
            "Zero Hunger and Good Health Contribution Certificate",
            donor.getFullName() + " is recognized for verified contribution(s) that supported safe food and medicine distribution."
        );
    }

    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    public String downloadDonorCertificateHtml(UserPrincipal principal) {
        DonorCertificateDetailResponse certificate = getDonorCertificateDetail(principal);
        return """
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="utf-8" />
              <title>%s</title>
              <style>
                body { font-family: Georgia, serif; background: #f7f3eb; margin: 0; padding: 32px; color: #17302a; }
                .sheet { max-width: 860px; margin: 0 auto; background: #fffdf8; border: 2px solid #cdbb94; padding: 48px; box-shadow: 0 20px 60px rgba(0,0,0,0.08); }
                .eyebrow { letter-spacing: 0.3em; text-transform: uppercase; font-size: 12px; color: #8a6a2b; }
                h1 { margin: 16px 0 10px; font-size: 42px; }
                h2 { margin: 0 0 28px; font-size: 22px; font-weight: normal; color: #3d5c53; }
                .recipient { font-size: 34px; margin: 28px 0 10px; }
                .statement { font-size: 18px; line-height: 1.6; }
                .grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; margin: 32px 0; }
                .metric { border: 1px solid #eadfcb; border-radius: 16px; padding: 18px; background: #fcfaf5; }
                .metric strong { display: block; font-size: 28px; margin-top: 6px; }
                .footer { margin-top: 36px; display: flex; justify-content: space-between; gap: 16px; font-size: 14px; color: #4a5f59; }
              </style>
            </head>
            <body>
              <div class="sheet">
                <div class="eyebrow">Vortex Synergy Certificate</div>
                <h1>%s</h1>
                <h2>%s</h2>
                <div class="recipient">%s</div>
                <p class="statement">%s</p>
                <div class="grid">
                  <div class="metric">Verified contributions<strong>%d</strong></div>
                  <div class="metric">Impact count<strong>%d</strong></div>
                </div>
                <div class="footer">
                  <div>
                    <div>Certificate number</div>
                    <strong>%s</strong>
                  </div>
                  <div>
                    <div>Issued at</div>
                    <strong>%s</strong>
                  </div>
                  <div>
                    <div>Issued by</div>
                    <strong>%s</strong>
                  </div>
                </div>
              </div>
            </body>
            </html>
            """.formatted(
            escapeHtml(certificate.programName()),
            escapeHtml(certificate.statement()),
            escapeHtml(certificate.programName()),
            escapeHtml(certificate.donorName()),
            escapeHtml(certificate.statement()),
            certificate.numberOfContributions(),
            certificate.impactCount(),
            escapeHtml(certificate.certificateNumber()),
            DateTimeFormatter.ofPattern("dd MMM yyyy, hh:mm a 'UTC'").withZone(ZoneOffset.UTC).format(certificate.issuedAt()),
            escapeHtml(certificate.issuedBy())
        );
    }

    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    public RoleDashboardResponse getRoleSummary(UserPrincipal principal) {
        var user = userRepository.findById(principal.getId())
            .orElseThrow(() -> new NotFoundException("User not found"));

        Set<DeliveryStatus> activeDeliveryStates = Set.of(
            DeliveryStatus.ASSIGNED,
            DeliveryStatus.PICKUP_PENDING,
            DeliveryStatus.PICKUP_APPROVED,
            DeliveryStatus.IN_TRANSIT
        );

        long unreadNotifications = notificationRepository.countByUserIdAndReadFalse(user.getId());
        long activeDonations = 0;
        long claimedDonations = 0;
        long expiredDonations = 0;
        long assignedDeliveryCount = 0;
        long activeClaims = 0;
        long completedClaims = 0;
        long activeDeliveryCount = 0;
        long completedDeliveryCount = 0;
        long urgentClaimCount = 0;
        long pendingVerificationCount = 0;
        long approvedVerificationCount = 0;
        long rejectedVerificationCount = 0;
        long pendingUserApprovalCount = 0;
        long moderatedResourceCount = 0;
        long activeSystemDeliveryCount = 0;
        long totalMealsSaved = 0;
        long medicineKitsDistributed = 0;

        List<Verification> pendingVerifications = verificationRepository.findByStatusOrderByCreatedAtAsc(VerificationStatus.PENDING);

        switch (user.getRole()) {
            case DONOR -> {
                activeDonations = resourceRepository.countByDonorIdAndStatusIn(
                    user.getId(),
                    List.of(ResourceStatus.AVAILABLE, ResourceStatus.RESERVED)
                );
                claimedDonations = resourceRepository.countByDonorIdAndStatus(user.getId(), ResourceStatus.CLAIMED);
                expiredDonations = resourceRepository.countByDonorIdAndStatus(user.getId(), ResourceStatus.EXPIRED);
                assignedDeliveryCount = deliveryRepository.countByClaimResourceDonorIdAndStatusIn(user.getId(), activeDeliveryStates);
            }
            case RECEIVER -> {
                activeClaims = claimRepository.countByReceiverIdAndStatusIn(user.getId(), Set.of(ClaimStatus.RESERVED));
                completedClaims = claimRepository.countByReceiverIdAndStatus(user.getId(), ClaimStatus.CLAIMED);
                activeDeliveryCount = deliveryRepository.countByReceiverIdAndStatusIn(user.getId(), activeDeliveryStates);
                completedDeliveryCount = deliveryRepository.countByReceiverIdAndStatus(user.getId(), DeliveryStatus.DELIVERED);
                urgentClaimCount = claimRepository.findByReceiverIdOrderByCreatedAtDesc(user.getId()).stream()
                    .filter(claim -> claim.getStatus() == ClaimStatus.RESERVED)
                    .filter(claim -> claim.getPriorityScore() != null && claim.getPriorityScore() >= 70)
                    .count();
            }
            case DOCTOR_PHARMACIST -> {
                pendingVerificationCount = pendingVerifications.stream()
                    .filter(verification -> verification.getVerificationType() == VerificationType.MEDICINE_LISTING)
                    .count();
                approvedVerificationCount = verificationRepository.countByReviewedByIdAndStatusAndVerificationType(
                    user.getId(),
                    VerificationStatus.APPROVED,
                    VerificationType.MEDICINE_LISTING
                );
                rejectedVerificationCount = verificationRepository.countByReviewedByIdAndStatusAndVerificationType(
                    user.getId(),
                    VerificationStatus.REJECTED,
                    VerificationType.MEDICINE_LISTING
                );
            }
            case ADMIN -> {
                pendingVerificationCount = pendingVerifications.stream()
                    .filter(verification -> verification.getVerificationType() == VerificationType.MEDICINE_LISTING)
                    .count();
                pendingUserApprovalCount = pendingVerifications.stream()
                    .filter(this::isAdminApprovalQueue)
                    .count();
                moderatedResourceCount = resourceRepository.countByStatus(ResourceStatus.CANCELLED);
                activeSystemDeliveryCount = deliveryRepository.countByStatusIn(activeDeliveryStates);
                totalMealsSaved = claimRepository.sumClaimedQuantityByType(ResourceType.FOOD);
                medicineKitsDistributed = claimRepository.sumClaimedQuantityByType(ResourceType.MEDICINE);
            }
            default -> {
            }
        }

        return new RoleDashboardResponse(
            user.getRole().name(),
            unreadNotifications,
            activeDonations,
            claimedDonations,
            expiredDonations,
            assignedDeliveryCount,
            activeClaims,
            completedClaims,
            activeDeliveryCount,
            completedDeliveryCount,
            urgentClaimCount,
            pendingVerificationCount,
            approvedVerificationCount,
            rejectedVerificationCount,
            pendingUserApprovalCount,
            moderatedResourceCount,
            activeSystemDeliveryCount,
            totalMealsSaved,
            medicineKitsDistributed
        );
    }

    private boolean isAdminApprovalQueue(Verification verification) {
        return verification.getVerificationType() == VerificationType.PROFESSIONAL_ACCOUNT
            || verification.getVerificationType() == VerificationType.MEDICINE_DONOR;
    }

    private String buildCertificateNumber(String donorId, Instant issuedAt) {
        String datePart = DateTimeFormatter.ofPattern("yyyyMMdd").withZone(ZoneOffset.UTC).format(issuedAt);
        return "VXS-" + datePart + "-" + donorId.substring(0, 8).toUpperCase();
    }

    private String escapeHtml(String value) {
        return value
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;");
    }
}

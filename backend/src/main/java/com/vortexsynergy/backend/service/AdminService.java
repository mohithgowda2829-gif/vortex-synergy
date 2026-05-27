package com.vortexsynergy.backend.service;

import com.vortexsynergy.backend.dto.admin.AdminDecisionRequest;
import com.vortexsynergy.backend.dto.admin.VerificationResponse;
import com.vortexsynergy.backend.dto.common.ApiMessageResponse;
import com.vortexsynergy.backend.dto.dashboard.DashboardSummaryResponse;
import com.vortexsynergy.backend.dto.resource.ResourceResponse;
import com.vortexsynergy.backend.exception.BadRequestException;
import com.vortexsynergy.backend.exception.NotFoundException;
import com.vortexsynergy.backend.model.Resource;
import com.vortexsynergy.backend.model.User;
import com.vortexsynergy.backend.model.Verification;
import com.vortexsynergy.backend.model.enums.NotificationType;
import com.vortexsynergy.backend.model.enums.ResourceStatus;
import com.vortexsynergy.backend.model.enums.ResourceType;
import com.vortexsynergy.backend.model.enums.VerificationStatus;
import com.vortexsynergy.backend.model.enums.VerificationTargetType;
import com.vortexsynergy.backend.model.enums.VerificationType;
import com.vortexsynergy.backend.repository.ResourceRepository;
import com.vortexsynergy.backend.repository.UserRepository;
import com.vortexsynergy.backend.repository.VerificationRepository;
import com.vortexsynergy.backend.security.UserPrincipal;
import jakarta.transaction.Transactional;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final VerificationRepository verificationRepository;
    private final UserRepository userRepository;
    private final ResourceRepository resourceRepository;
    private final DashboardService dashboardService;
    private final UserService userService;
    private final ResourceService resourceService;
    private final AuditService auditService;
    private final NotificationService notificationService;

    @Transactional
    public List<VerificationResponse> getPendingVerifications() {
        return verificationRepository.findByStatusOrderByCreatedAtAsc(VerificationStatus.PENDING).stream()
            .map(verification -> VerificationResponse.from(verification, resolveSubjectName(verification)))
            .toList();
    }

    @Transactional
    public VerificationResponse decideVerification(UserPrincipal principal, UUID verificationId, AdminDecisionRequest request) {
        User admin = userService.getCurrentUserEntity(principal);
        Verification verification = verificationRepository.findById(verificationId)
            .orElseThrow(() -> new NotFoundException("Verification not found"));

        if (verification.getStatus() != VerificationStatus.PENDING) {
            throw new BadRequestException("Verification is already processed");
        }

        verification.setStatus(Boolean.TRUE.equals(request.approved()) ? VerificationStatus.APPROVED : VerificationStatus.REJECTED);
        verification.setReviewedBy(admin);
        verification.setReviewedAt(Instant.now());
        verification.setNote(request.note());
        verificationRepository.save(verification);

        if (verification.getTargetType() == VerificationTargetType.USER) {
            User user = userRepository.findById(verification.getTargetId())
                .orElseThrow(() -> new NotFoundException("Verification target user not found"));
            applyUserVerificationDecision(user, verification);
        }

        auditService.log(admin, "VERIFICATION_DECIDED", "VERIFICATION", verification.getId().toString(), String.valueOf(request.approved()));
        return VerificationResponse.from(verification, resolveSubjectName(verification));
    }

    @Transactional
    public List<ResourceResponse> getAllResources() {
        return resourceRepository.findAllByOrderByCreatedAtDesc().stream()
            .map(resource -> ResourceResponse.from(resource, resourceService.isClaimable(resource)))
            .toList();
    }

    @Transactional
    public ApiMessageResponse removeResource(UserPrincipal principal, UUID resourceId) {
        User admin = userService.getCurrentUserEntity(principal);
        Resource resource = resourceService.findResource(resourceId);
        resource.setStatus(ResourceStatus.CANCELLED);
        resourceRepository.save(resource);
        notificationService.notifyUser(
            resource.getDonor(),
            NotificationType.ADMIN_MODERATION,
            "Resource moderated",
            resource.getTitle() + " was removed by an administrator"
        );
        auditService.log(admin, "RESOURCE_REMOVED", "RESOURCE", resource.getId().toString(), "Resource removed by admin");
        return new ApiMessageResponse("Resource removed successfully");
    }

    public DashboardSummaryResponse getAnalytics() {
        return dashboardService.getSummary();
    }

    private void applyUserVerificationDecision(User user, Verification verification) {
        if (verification.getVerificationType() == VerificationType.PROFESSIONAL_ACCOUNT) {
            user.setAdminApproved(verification.getStatus() == VerificationStatus.APPROVED);
            user.setAccountVerified(userService.isAccountVerified(user));
            userRepository.save(user);
            return;
        }

        if (verification.getVerificationType() == VerificationType.MEDICINE_DONOR
            && verification.getStatus() == VerificationStatus.REJECTED) {
            List<Resource> resources = resourceRepository.findByDonorIdAndResourceType(user.getId(), ResourceType.MEDICINE);
            for (Resource resource : resources) {
                if (resource.getStatus() != ResourceStatus.CLAIMED && resource.getStatus() != ResourceStatus.EXPIRED) {
                    resource.setStatus(ResourceStatus.CANCELLED);
                }
            }
            resourceRepository.saveAll(resources);
        }
    }

    private String resolveSubjectName(Verification verification) {
        if (verification.getTargetType() == VerificationTargetType.USER) {
            return userRepository.findById(verification.getTargetId()).map(User::getFullName).orElse("Unknown user");
        }
        return resourceRepository.findById(verification.getTargetId()).map(Resource::getTitle).orElse("Unknown resource");
    }
}

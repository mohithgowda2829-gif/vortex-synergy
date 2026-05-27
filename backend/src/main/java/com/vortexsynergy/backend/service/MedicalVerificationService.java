package com.vortexsynergy.backend.service;

import com.vortexsynergy.backend.dto.resource.MedicalVerificationRequest;
import com.vortexsynergy.backend.dto.resource.ResourceResponse;
import com.vortexsynergy.backend.exception.BadRequestException;
import com.vortexsynergy.backend.exception.NotFoundException;
import com.vortexsynergy.backend.exception.ForbiddenException;
import com.vortexsynergy.backend.model.Resource;
import com.vortexsynergy.backend.model.User;
import com.vortexsynergy.backend.model.Verification;
import com.vortexsynergy.backend.model.enums.NotificationType;
import com.vortexsynergy.backend.model.enums.ResourceStatus;
import com.vortexsynergy.backend.model.enums.ResourceType;
import com.vortexsynergy.backend.model.enums.Role;
import com.vortexsynergy.backend.model.enums.VerificationStatus;
import com.vortexsynergy.backend.model.enums.VerificationTargetType;
import com.vortexsynergy.backend.model.enums.VerificationType;
import com.vortexsynergy.backend.repository.ResourceRepository;
import com.vortexsynergy.backend.repository.UserRepository;
import com.vortexsynergy.backend.repository.VerificationRepository;
import com.vortexsynergy.backend.security.UserPrincipal;
import jakarta.transaction.Transactional;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class MedicalVerificationService {

    private final ResourceRepository resourceRepository;
    private final UserRepository userRepository;
    private final VerificationRepository verificationRepository;
    private final ResourceService resourceService;
    private final AuditService auditService;
    private final NotificationService notificationService;

    @Transactional
    public List<ResourceResponse> getPendingMedicineResources() {
        Specification<Resource> specification = (root, query, cb) -> cb.and(
            cb.equal(root.get("resourceType"), ResourceType.MEDICINE),
            cb.equal(root.get("medicalVerificationStatus"), VerificationStatus.PENDING),
            cb.notEqual(root.get("status"), ResourceStatus.CANCELLED),
            cb.notEqual(root.get("status"), ResourceStatus.EXPIRED),
            cb.notEqual(root.get("status"), ResourceStatus.CLAIMED)
        );

        return resourceRepository.findAll(specification).stream()
            .map(resource -> ResourceResponse.from(resource, resourceService.isClaimable(resource)))
            .toList();
    }

    @Transactional
    public List<ResourceResponse> getReviewedMedicineResources(UserPrincipal principal) {
        User reviewer = userRepository.findById(principal.getId())
            .orElseThrow(() -> new NotFoundException("User not found"));
        if (reviewer.getRole() != Role.DOCTOR_PHARMACIST && reviewer.getRole() != Role.ADMIN) {
            throw new ForbiddenException("Only doctors, pharmacists, or admins can view review history");
        }

        return resourceRepository.findByMedicalVerifiedByIdAndResourceTypeOrderByMedicalVerifiedAtDesc(
                reviewer.getId(),
                ResourceType.MEDICINE
            ).stream()
            .map(resource -> ResourceResponse.from(resource, resourceService.isClaimable(resource)))
            .toList();
    }

    @Transactional
    public ResourceResponse verifyMedicine(UserPrincipal principal, UUID resourceId, MedicalVerificationRequest request) {
        return decide(principal, resourceId, request, true);
    }

    @Transactional
    public ResourceResponse rejectMedicine(UserPrincipal principal, UUID resourceId, MedicalVerificationRequest request) {
        return decide(principal, resourceId, request, false);
    }

    private ResourceResponse decide(UserPrincipal principal, UUID resourceId, MedicalVerificationRequest request, boolean approved) {
        User reviewer = userRepository.findById(principal.getId())
            .orElseThrow(() -> new NotFoundException("User not found"));
        Resource resource = resourceService.findResource(resourceId);

        if (resource.getResourceType() != ResourceType.MEDICINE) {
            throw new BadRequestException("Only medicine resources can be medically verified");
        }
        if (resource.getMedicalVerificationStatus() != VerificationStatus.PENDING) {
            throw new BadRequestException("This medicine listing has already been reviewed");
        }
        if (resource.getMedicineSealStatus() == null || resource.getMedicineSealStatus().name().equals("OPENED")) {
            throw new BadRequestException("Opened medicines must be rejected");
        }
        if (resource.getMedicineExpiryDate() != null && resource.getMedicineExpiryDate().isBefore(LocalDate.now())) {
            throw new BadRequestException("Expired medicines must be rejected");
        }

        Verification verification = verificationRepository
            .findFirstByTargetTypeAndTargetIdAndVerificationTypeOrderByCreatedAtDesc(
                VerificationTargetType.RESOURCE,
                resource.getId(),
                VerificationType.MEDICINE_LISTING
            )
            .orElseGet(() -> Verification.builder()
                .targetType(VerificationTargetType.RESOURCE)
                .targetId(resource.getId())
                .verificationType(VerificationType.MEDICINE_LISTING)
                .requestedBy(resource.getDonor())
                .build());

        resource.setMedicalVerifiedBy(reviewer);
        resource.setMedicalVerifiedAt(Instant.now());
        resource.setMedicalVerificationNote(request.note());
        resource.setVerificationNotes(request.verificationNotes() != null ? request.verificationNotes() : request.note());
        verification.setReviewedBy(reviewer);
        verification.setReviewedAt(Instant.now());
        verification.setNote(request.note());

        if (approved) {
            resource.setMedicalVerificationStatus(VerificationStatus.APPROVED);
            resource.setStatus(resource.getAvailableQuantity() > 0 ? ResourceStatus.AVAILABLE : ResourceStatus.RESERVED);
            verification.setStatus(VerificationStatus.APPROVED);
            notificationService.notifyUser(
                resource.getDonor(),
                NotificationType.MEDICINE_APPROVED,
                "Medicine approved",
                resource.getTitle() + " was approved with reviewer notes"
            );
            auditService.log(
                reviewer,
                "MEDICINE_APPROVED",
                "RESOURCE",
                resource.getId().toString(),
                request.note(),
                "{\"verificationNotes\":\"" + safeJson(request.verificationNotes()) + "\"}"
            );
        } else {
            resource.setMedicalVerificationStatus(VerificationStatus.REJECTED);
            resource.setStatus(ResourceStatus.CANCELLED);
            verification.setStatus(VerificationStatus.REJECTED);
            notificationService.notifyUser(
                resource.getDonor(),
                NotificationType.MEDICINE_REJECTED,
                "Medicine rejected",
                resource.getTitle() + " was rejected during compliance review"
            );
            auditService.log(
                reviewer,
                "MEDICINE_REJECTED",
                "RESOURCE",
                resource.getId().toString(),
                request.note(),
                "{\"verificationNotes\":\"" + safeJson(request.verificationNotes()) + "\"}"
            );
        }

        verificationRepository.save(verification);
        resourceRepository.save(resource);
        return ResourceResponse.from(resource, resourceService.isClaimable(resource));
    }

    private String safeJson(String value) {
        return value == null ? "" : value.replace("\"", "\\\"");
    }
}

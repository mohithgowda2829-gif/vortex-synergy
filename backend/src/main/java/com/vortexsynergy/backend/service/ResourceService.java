package com.vortexsynergy.backend.service;

import com.vortexsynergy.backend.dto.resource.CreateResourceRequest;
import com.vortexsynergy.backend.dto.resource.ResourceResponse;
import com.vortexsynergy.backend.dto.common.ApiMessageResponse;
import com.vortexsynergy.backend.dto.common.PagedResponse;
import com.vortexsynergy.backend.exception.BadRequestException;
import com.vortexsynergy.backend.exception.ForbiddenException;
import com.vortexsynergy.backend.exception.NotFoundException;
import com.vortexsynergy.backend.model.Resource;
import com.vortexsynergy.backend.model.User;
import com.vortexsynergy.backend.model.Verification;
import com.vortexsynergy.backend.model.enums.MedicineSealStatus;
import com.vortexsynergy.backend.model.enums.NotificationType;
import com.vortexsynergy.backend.model.enums.ResourceStatus;
import com.vortexsynergy.backend.model.enums.ResourceType;
import com.vortexsynergy.backend.model.enums.Role;
import com.vortexsynergy.backend.model.enums.VerificationStatus;
import com.vortexsynergy.backend.model.enums.VerificationTargetType;
import com.vortexsynergy.backend.model.enums.VerificationType;
import com.vortexsynergy.backend.repository.ResourceBrowseRepository;
import com.vortexsynergy.backend.repository.ResourceRepository;
import com.vortexsynergy.backend.repository.UserRepository;
import com.vortexsynergy.backend.repository.VerificationRepository;
import com.vortexsynergy.backend.security.UserPrincipal;
import jakarta.transaction.Transactional;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class ResourceService {

    private final ResourceRepository resourceRepository;
    private final UserRepository userRepository;
    private final VerificationRepository verificationRepository;
    private final AuditService auditService;
    private final NotificationService notificationService;

    @Value("${app.food.safe-window-hours}")
    private long foodSafeWindowHours;

    @Transactional
    public ResourceResponse createResource(UserPrincipal principal, CreateResourceRequest request) {
        User donor = currentUser(principal);

        if (donor.getRole() != Role.DONOR) {
            throw new BadRequestException("Only donors can create resources");
        }
        if (!donor.isAccountVerified()) {
            throw new BadRequestException("Donor account must be phone and email verified first");
        }
        if ((request.latitude() == null) != (request.longitude() == null)) {
            throw new BadRequestException("Latitude and longitude must both be provided together");
        }

        Resource resource = Resource.builder()
            .donor(donor)
            .resourceType(request.resourceType())
            .title(request.title().trim())
            .description(trimToNull(request.description()))
            .quantity(request.quantity())
            .availableQuantity(request.quantity())
            .unit(request.unit().trim())
            .status(ResourceStatus.AVAILABLE)
            .city(request.city().trim())
            .area(request.area().trim())
            .latitude(request.latitude())
            .longitude(request.longitude())
            .locationNote(trimToNull(request.locationNote()))
            .requiresReceiverDelivery(Boolean.TRUE.equals(request.requiresReceiverDelivery()))
            .photoUrls(request.photoUrls() == null ? List.of() : request.photoUrls().stream()
                .filter(url -> url != null && !url.isBlank())
                .toList())
            .medicalVerificationStatus(request.resourceType() == ResourceType.MEDICINE
                ? VerificationStatus.PENDING
                : VerificationStatus.APPROVED)
            .build();

        if (request.resourceType() == ResourceType.FOOD) {
            prepareFoodResource(resource, request);
        } else {
            prepareMedicineResource(resource, request, donor);
        }

        resourceRepository.save(resource);

        if (resource.getResourceType() == ResourceType.MEDICINE) {
            upsertMedicineListingVerification(resource, donor, "Pending doctor or pharmacist review");
        }

        auditService.log(
            donor,
            "RESOURCE_CREATED",
            "RESOURCE",
            resource.getId().toString(),
            resource.getResourceType().name(),
            "{\"city\":\"" + resource.getCity() + "\",\"area\":\"" + resource.getArea() + "\"}"
        );
        return ResourceResponse.from(resource, isClaimable(resource));
    }

    @Transactional
    public ResourceResponse updateResource(UserPrincipal principal, UUID resourceId, CreateResourceRequest request) {
        User actor = currentUser(principal);
        Resource resource = findResource(resourceId);
        ensureResourceOwnerOrAdmin(actor, resource);
        ensureResourceEditable(resource);

        if (request.resourceType() != resource.getResourceType()) {
            throw new BadRequestException("Resource type cannot be changed after creation");
        }
        if (!resource.getDonor().isAccountVerified()) {
            throw new BadRequestException("Donor account must remain verified to update a listing");
        }
        if ((request.latitude() == null) != (request.longitude() == null)) {
            throw new BadRequestException("Latitude and longitude must both be provided together");
        }

        resource.setTitle(request.title().trim());
        resource.setDescription(trimToNull(request.description()));
        resource.setQuantity(request.quantity());
        resource.setAvailableQuantity(request.quantity());
        resource.setUnit(request.unit().trim());
        resource.setCity(request.city().trim());
        resource.setArea(request.area().trim());
        resource.setLatitude(request.latitude());
        resource.setLongitude(request.longitude());
        resource.setLocationNote(trimToNull(request.locationNote()));
        resource.setRequiresReceiverDelivery(Boolean.TRUE.equals(request.requiresReceiverDelivery()));
        resource.setPhotoUrls(request.photoUrls() == null ? List.of() : request.photoUrls().stream()
            .filter(url -> url != null && !url.isBlank())
            .toList());
        resource.setExpiryWarningSentAt(null);

        if (resource.getResourceType() == ResourceType.FOOD) {
            prepareFoodResource(resource, request);
        } else {
            prepareMedicineResource(resource, request, resource.getDonor());
            resource.setMedicalVerificationStatus(VerificationStatus.PENDING);
            resource.setMedicalVerifiedBy(null);
            resource.setMedicalVerifiedAt(null);
            resource.setMedicalVerificationNote(null);
            resource.setVerificationNotes(null);
            upsertMedicineListingVerification(resource, resource.getDonor(), "Pending doctor or pharmacist review after donor update");
        }

        resourceRepository.save(resource);
        auditService.log(
            actor,
            "RESOURCE_UPDATED",
            "RESOURCE",
            resource.getId().toString(),
            "Resource updated before claims or handover"
        );
        return ResourceResponse.from(resource, isClaimable(resource));
    }

    @Transactional
    public ApiMessageResponse cancelResource(UserPrincipal principal, UUID resourceId) {
        User actor = currentUser(principal);
        Resource resource = findResource(resourceId);
        ensureResourceOwnerOrAdmin(actor, resource);
        ensureResourceEditable(resource);

        resource.setStatus(ResourceStatus.CANCELLED);
        resourceRepository.save(resource);
        auditService.log(actor, "RESOURCE_CANCELLED", "RESOURCE", resource.getId().toString(), "Resource cancelled by owner");
        return new ApiMessageResponse("Resource cancelled successfully");
    }

    @Transactional
    public PagedResponse<ResourceResponse> getResources(
        ResourceType resourceType,
        String query,
        String city,
        String area,
        String sort,
        Double latitude,
        Double longitude,
        Integer page,
        Integer size
    ) {
        if ((latitude == null) != (longitude == null)) {
            throw new BadRequestException("Latitude and longitude must both be provided together");
        }

        String normalizedSort = sort == null ? "EXPIRY" : sort.trim().toUpperCase(Locale.ROOT);
        if ("NEAREST".equals(normalizedSort) && (latitude == null || longitude == null)) {
            throw new BadRequestException("Latitude and longitude are required for nearest sorting");
        }

        int safePage = page == null ? 0 : page;
        int safeSize = size == null ? 20 : size;
        if (safePage < 0) {
            throw new BadRequestException("Page must be 0 or greater");
        }
        if (safeSize < 1 || safeSize > 50) {
            throw new BadRequestException("Size must be between 1 and 50");
        }

        Page<ResourceBrowseRepository.ResourceBrowseRow> browsePage = resourceRepository.searchPublicResources(
            new ResourceBrowseRepository.ResourceBrowseQuery(
                resourceType,
                query,
                city,
                area,
                latitude,
                longitude,
                normalizedSort
            ),
            PageRequest.of(safePage, safeSize)
        );

        List<UUID> orderedIds = browsePage.getContent().stream()
            .map(ResourceBrowseRepository.ResourceBrowseRow::resourceId)
            .toList();
        Map<UUID, Resource> resourceById = orderedIds.isEmpty()
            ? Map.of()
            : resourceRepository.findAllById(orderedIds).stream()
                .collect(Collectors.toMap(Resource::getId, Function.identity(), (left, right) -> left));

        List<ResourceResponse> items = orderedIds.stream()
            .map(resourceById::get)
            .filter(resource -> resource != null)
            .map(resource -> ResourceResponse.from(resource, isClaimable(resource), distanceKm(resource, latitude, longitude)))
            .toList();

        Page<ResourceResponse> responsePage = new PageImpl<>(items, browsePage.getPageable(), browsePage.getTotalElements());
        return PagedResponse.from(responsePage);
    }

    @Transactional
    public ResourceResponse getResource(UUID id, UserPrincipal principal) {
        Resource resource = findResource(id);
        User currentUser = userRepository.findById(principal.getId())
            .orElseThrow(() -> new NotFoundException("User not found"));

        boolean privileged = currentUser.getRole() == Role.ADMIN
            || currentUser.getRole() == Role.DOCTOR_PHARMACIST
            || resource.getDonor().getId().equals(currentUser.getId());

        if (!privileged && !isPubliclyVisible(resource)) {
            throw new NotFoundException("Resource not found");
        }

        return ResourceResponse.from(resource, isClaimable(resource));
    }

    @Transactional
    public List<ResourceResponse> getMyResources(UserPrincipal principal) {
        return resourceRepository.findByDonorIdOrderByCreatedAtDesc(principal.getId()).stream()
            .map(resource -> ResourceResponse.from(resource, isClaimable(resource)))
            .toList();
    }

    public Resource findResource(UUID resourceId) {
        return resourceRepository.findById(resourceId)
            .orElseThrow(() -> new NotFoundException("Resource not found"));
    }

    public boolean isClaimable(Resource resource) {
        if (resource.getStatus() == ResourceStatus.CANCELLED
            || resource.getStatus() == ResourceStatus.EXPIRED
            || resource.getStatus() == ResourceStatus.CLAIMED
            || resource.getAvailableQuantity() <= 0) {
            return false;
        }

        if (resource.getResourceType() == ResourceType.FOOD) {
            return resource.getDonor().isAccountVerified() && !hasFoodExpired(resource);
        }

        return resource.getMedicalVerificationStatus() == VerificationStatus.APPROVED
            && hasApprovedMedicineDonorVerification(resource.getDonor())
            && resource.getMedicineSealStatus() == MedicineSealStatus.SEALED
            && !hasMedicineExpired(resource);
    }

    public boolean isPubliclyVisible(Resource resource) {
        return isClaimable(resource);
    }

    @Transactional
    @Scheduled(fixedDelayString = "${app.scheduler.expiry-check-ms}")
    public void expireStaleResources() {
        List<Resource> expiredResources = resourceRepository.findExpiredResources(LocalDateTime.now(), LocalDate.now());
        for (Resource resource : expiredResources) {
            resource.setStatus(ResourceStatus.EXPIRED);
            resourceRepository.save(resource);
            auditService.log(null, "RESOURCE_EXPIRED", "RESOURCE", resource.getId().toString(), "Resource expired automatically");
        }
    }

    @Transactional
    @Scheduled(fixedDelayString = "${app.scheduler.expiry-check-ms}")
    public void notifyExpiringSoonResources() {
        List<Resource> candidates = resourceRepository.findAll().stream()
            .filter(resource -> resource.getStatus() != ResourceStatus.CANCELLED
                && resource.getStatus() != ResourceStatus.EXPIRED
                && resource.getStatus() != ResourceStatus.CLAIMED)
            .filter(resource -> resource.getExpiryWarningSentAt() == null)
            .filter(this::isExpiringSoon)
            .toList();

        for (Resource resource : candidates) {
            resource.setExpiryWarningSentAt(Instant.now());
            resourceRepository.save(resource);
            notificationService.notifyUser(
                resource.getDonor(),
                NotificationType.RESOURCE_EXPIRING_SOON,
                "Resource expiring soon",
                resource.getTitle() + " is approaching expiry and should be handled quickly"
            );
            auditService.log(null, "RESOURCE_EXPIRY_WARNING", "RESOURCE", resource.getId().toString(), "Expiry warning sent");
        }
    }

    private void prepareFoodResource(Resource resource, CreateResourceRequest request) {
        if (request.preparedTime() == null) {
            throw new BadRequestException("Prepared time is required for food resources");
        }

        LocalDateTime expiresAt = request.expiryTime() != null
            ? request.expiryTime()
            : request.preparedTime().plusHours(foodSafeWindowHours);

        if (!expiresAt.isAfter(request.preparedTime())) {
            throw new BadRequestException("Food expiry must be after prepared time");
        }
        if (!expiresAt.isAfter(LocalDateTime.now())) {
            throw new BadRequestException("Food resource is already expired");
        }

        resource.setFoodType(trimToNull(request.foodType()));
        resource.setPreparedTime(request.preparedTime());
        resource.setExpiresAt(expiresAt);
    }

    private void prepareMedicineResource(Resource resource, CreateResourceRequest request, User donor) {
        if (request.medicineName() == null || request.medicineName().isBlank()) {
            throw new BadRequestException("Medicine name is required");
        }
        if (request.batchNumber() == null || request.batchNumber().isBlank()) {
            throw new BadRequestException("Batch number is required");
        }
        if (request.medicineExpiryDate() == null) {
            throw new BadRequestException("Medicine expiry date is required");
        }
        if (request.medicineSealStatus() == MedicineSealStatus.OPENED) {
            throw new BadRequestException("Opened medicines are not accepted");
        }
        if (request.medicineExpiryDate().isBefore(LocalDate.now())) {
            throw new BadRequestException("Expired medicines cannot be uploaded");
        }

        resource.setMedicineName(request.medicineName().trim());
        resource.setMedicineExpiryDate(request.medicineExpiryDate());
        resource.setMedicineSealStatus(request.medicineSealStatus());
        resource.setBatchNumber(request.batchNumber().trim());
        resource.setMedicineCategory(trimToNull(request.medicineCategory()));
        resource.setMedicineAccessType(request.medicineAccessType());
        resource.setPrescriptionRequired(Boolean.TRUE.equals(request.prescriptionRequired()));

        ensureMedicineDonorVerification(donor);
    }

    private void ensureMedicineDonorVerification(User donor) {
        Verification verification = verificationRepository
            .findFirstByTargetTypeAndTargetIdAndVerificationTypeOrderByCreatedAtDesc(
                VerificationTargetType.USER,
                donor.getId(),
                VerificationType.MEDICINE_DONOR
            )
            .orElse(null);

        if (verification == null) {
            verificationRepository.save(Verification.builder()
                .targetType(VerificationTargetType.USER)
                .targetId(donor.getId())
                .verificationType(VerificationType.MEDICINE_DONOR)
                .status(VerificationStatus.PENDING)
                .requestedBy(donor)
                .note("Pending admin approval for medicine donation flow")
                .build());
        }
    }

    private boolean hasApprovedMedicineDonorVerification(User donor) {
        return verificationRepository
            .findFirstByTargetTypeAndTargetIdAndVerificationTypeOrderByCreatedAtDesc(
                VerificationTargetType.USER,
                donor.getId(),
                VerificationType.MEDICINE_DONOR
            )
            .map(verification -> verification.getStatus() == VerificationStatus.APPROVED)
            .orElse(false);
    }

    private void upsertMedicineListingVerification(Resource resource, User donor, String note) {
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
                .requestedBy(donor)
                .build());

        verification.setStatus(VerificationStatus.PENDING);
        verification.setRequestedBy(donor);
        verification.setReviewedBy(null);
        verification.setReviewedAt(null);
        verification.setNote(note);
        verificationRepository.save(verification);
    }

    private boolean hasFoodExpired(Resource resource) {
        return resource.getExpiresAt() != null && !resource.getExpiresAt().isAfter(LocalDateTime.now());
    }

    private boolean hasMedicineExpired(Resource resource) {
        return resource.getMedicineExpiryDate() != null && resource.getMedicineExpiryDate().isBefore(LocalDate.now());
    }

    private boolean isExpiringSoon(Resource resource) {
        if (resource.getResourceType() == ResourceType.FOOD) {
            return resource.getExpiresAt() != null && resource.getExpiresAt().isBefore(LocalDateTime.now().plusHours(1));
        }

        return resource.getMedicineExpiryDate() != null
            && !resource.getMedicineExpiryDate().isAfter(LocalDate.now().plusDays(2));
    }

    private Comparator<Resource> buildComparator(String sort, Double latitude, Double longitude) {
        String normalizedSort = sort == null ? "EXPIRY" : sort.trim().toUpperCase(Locale.ROOT);
        if ("LOCATION".equals(normalizedSort)) {
            return Comparator.comparing(Resource::getCity, String.CASE_INSENSITIVE_ORDER)
                .thenComparing(Resource::getArea, String.CASE_INSENSITIVE_ORDER)
                .thenComparing(Resource::getCreatedAt);
        }
        if ("PRIORITY".equals(normalizedSort)) {
            return Comparator.comparing(this::resourcePriorityScore).reversed()
                .thenComparing(this::effectiveExpiry, Comparator.nullsLast(Comparator.naturalOrder()));
        }
        if ("NEAREST".equals(normalizedSort) && latitude != null && longitude != null) {
            return Comparator.comparing(
                    (Resource resource) -> distanceKm(resource, latitude, longitude),
                    Comparator.nullsLast(Comparator.naturalOrder())
                )
                .thenComparing(this::effectiveExpiry, Comparator.nullsLast(Comparator.naturalOrder()));
        }

        return Comparator.comparing(this::effectiveExpiry, Comparator.nullsLast(Comparator.naturalOrder()))
            .thenComparing(Resource::getCreatedAt);
    }

    private int resourcePriorityScore(Resource resource) {
        int score = 0;
        if (resource.getResourceType() == ResourceType.FOOD && resource.getExpiresAt() != null) {
            if (resource.getExpiresAt().isBefore(LocalDateTime.now().plusHours(2))) {
                score += 90;
            } else if (resource.getExpiresAt().isBefore(LocalDateTime.now().plusHours(6))) {
                score += 60;
            }
        }
        if (resource.getResourceType() == ResourceType.MEDICINE && resource.getMedicineExpiryDate() != null) {
            if (!resource.getMedicineExpiryDate().isAfter(LocalDate.now().plusDays(7))) {
                score += 70;
            } else if (!resource.getMedicineExpiryDate().isAfter(LocalDate.now().plusDays(30))) {
                score += 40;
            }
        }
        if (resource.getMedicalVerificationStatus() == VerificationStatus.APPROVED) {
            score += 5;
        }
        return score;
    }

    private LocalDateTime effectiveExpiry(Resource resource) {
        if (resource.getResourceType() == ResourceType.FOOD) {
            return resource.getExpiresAt();
        }
        return resource.getMedicineExpiryDate() != null
            ? resource.getMedicineExpiryDate().atStartOfDay()
            : null;
    }

    private Double distanceKm(Resource resource, Double latitude, Double longitude) {
        if (latitude == null || longitude == null || resource.getLatitude() == null || resource.getLongitude() == null) {
            return null;
        }

        double earthRadiusKm = 6371.0;
        double dLat = Math.toRadians(resource.getLatitude() - latitude);
        double dLon = Math.toRadians(resource.getLongitude() - longitude);
        double startLat = Math.toRadians(latitude);
        double endLat = Math.toRadians(resource.getLatitude());

        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
            + Math.sin(dLon / 2) * Math.sin(dLon / 2) * Math.cos(startLat) * Math.cos(endLat);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return Math.round(earthRadiusKm * c * 100.0) / 100.0;
    }

    private Specification<Resource> notTerminal() {
        return (root, query, cb) -> cb.and(
            cb.notEqual(root.get("status"), ResourceStatus.CANCELLED),
            cb.notEqual(root.get("status"), ResourceStatus.EXPIRED),
            cb.notEqual(root.get("status"), ResourceStatus.CLAIMED)
        );
    }

    private Specification<Resource> matchesType(ResourceType type) {
        return (root, query, cb) -> type == null ? cb.conjunction() : cb.equal(root.get("resourceType"), type);
    }

    private Specification<Resource> matchesQuery(String query) {
        return (root, criteriaQuery, cb) -> {
            if (query == null || query.isBlank()) {
                return cb.conjunction();
            }
            String like = "%" + query.trim().toLowerCase(Locale.ROOT) + "%";
            return cb.or(
                cb.like(cb.lower(root.get("title")), like),
                cb.like(cb.lower(cb.coalesce(root.get("medicineName"), "")), like),
                cb.like(cb.lower(cb.coalesce(root.get("foodType"), "")), like)
            );
        };
    }

    private Specification<Resource> matchesCity(String city) {
        return (root, query, cb) -> city == null || city.isBlank()
            ? cb.conjunction()
            : cb.equal(cb.lower(root.get("city")), city.trim().toLowerCase(Locale.ROOT));
    }

    private Specification<Resource> matchesArea(String area) {
        return (root, query, cb) -> area == null || area.isBlank()
            ? cb.conjunction()
            : cb.equal(cb.lower(root.get("area")), area.trim().toLowerCase(Locale.ROOT));
    }

    private void ensureResourceOwnerOrAdmin(User actor, Resource resource) {
        boolean allowed = actor.getRole() == Role.ADMIN || actor.getId().equals(resource.getDonor().getId());
        if (!allowed) {
            throw new ForbiddenException("You are not allowed to manage this resource");
        }
    }

    private void ensureResourceEditable(Resource resource) {
        if (resource.getStatus() != ResourceStatus.AVAILABLE) {
            throw new BadRequestException("Only available resources can be updated or cancelled");
        }
        if (!resource.getQuantity().equals(resource.getAvailableQuantity())) {
            throw new BadRequestException("Resources with active reservations or completed claims cannot be changed");
        }
    }

    private User currentUser(UserPrincipal principal) {
        return userRepository.findById(principal.getId())
            .orElseThrow(() -> new NotFoundException("User not found"));
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}

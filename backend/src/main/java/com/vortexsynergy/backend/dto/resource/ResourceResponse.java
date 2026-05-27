package com.vortexsynergy.backend.dto.resource;

import com.vortexsynergy.backend.model.Resource;
import com.vortexsynergy.backend.model.enums.MedicineAccessType;
import com.vortexsynergy.backend.model.enums.MedicineSealStatus;
import com.vortexsynergy.backend.model.enums.ResourceStatus;
import com.vortexsynergy.backend.model.enums.ResourceType;
import com.vortexsynergy.backend.model.enums.VerificationStatus;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public record ResourceResponse(
    UUID id,
    Instant createdAt,
    UUID donorId,
    String donorName,
    ResourceType resourceType,
    String title,
    String description,
    Integer quantity,
    Integer availableQuantity,
    String unit,
    ResourceStatus status,
    String city,
    String area,
    Double latitude,
    Double longitude,
    String locationNote,
    String foodType,
    LocalDateTime preparedTime,
    LocalDateTime expiresAt,
    String medicineName,
    LocalDate medicineExpiryDate,
    MedicineSealStatus medicineSealStatus,
    String batchNumber,
    String medicineCategory,
    MedicineAccessType medicineAccessType,
    Boolean prescriptionRequired,
    VerificationStatus medicalVerificationStatus,
    String verificationNotes,
    boolean requiresReceiverDelivery,
    List<String> photoUrls,
    Double distanceKm,
    boolean claimable
) {
    public static ResourceResponse from(Resource resource, boolean claimable) {
        return from(resource, claimable, null);
    }

    public static ResourceResponse from(Resource resource, boolean claimable, Double distanceKm) {
        return new ResourceResponse(
            resource.getId(),
            resource.getCreatedAt(),
            resource.getDonor().getId(),
            resource.getDonor().getFullName(),
            resource.getResourceType(),
            resource.getTitle(),
            resource.getDescription(),
            resource.getQuantity(),
            resource.getAvailableQuantity(),
            resource.getUnit(),
            resource.getStatus(),
            resource.getCity(),
            resource.getArea(),
            resource.getLatitude(),
            resource.getLongitude(),
            resource.getLocationNote(),
            resource.getFoodType(),
            resource.getPreparedTime(),
            resource.getExpiresAt(),
            resource.getMedicineName(),
            resource.getMedicineExpiryDate(),
            resource.getMedicineSealStatus(),
            resource.getBatchNumber(),
            resource.getMedicineCategory(),
            resource.getMedicineAccessType(),
            resource.getPrescriptionRequired(),
            resource.getMedicalVerificationStatus(),
            resource.getVerificationNotes() != null ? resource.getVerificationNotes() : resource.getMedicalVerificationNote(),
            resource.isRequiresReceiverDelivery(),
            resource.getPhotoUrls(),
            distanceKm,
            claimable
        );
    }
}

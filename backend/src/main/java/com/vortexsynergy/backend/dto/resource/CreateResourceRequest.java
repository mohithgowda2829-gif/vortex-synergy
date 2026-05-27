package com.vortexsynergy.backend.dto.resource;

import com.vortexsynergy.backend.model.enums.MedicineSealStatus;
import com.vortexsynergy.backend.model.enums.MedicineAccessType;
import com.vortexsynergy.backend.model.enums.ResourceType;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public record CreateResourceRequest(
    @NotNull(message = "Resource type is required")
    ResourceType resourceType,
    @NotBlank(message = "Title is required")
    @Size(max = 120, message = "Title must be 120 characters or fewer")
    String title,
    @Size(max = 1000, message = "Description must be 1000 characters or fewer")
    String description,
    @NotNull(message = "Quantity is required")
    @Min(value = 1, message = "Quantity must be greater than 0")
    Integer quantity,
    @NotBlank(message = "Unit is required")
    @Size(max = 40, message = "Unit must be 40 characters or fewer")
    String unit,
    @NotBlank(message = "City is required")
    @Size(max = 80, message = "City must be 80 characters or fewer")
    String city,
    @NotBlank(message = "Area is required")
    @Size(max = 80, message = "Area must be 80 characters or fewer")
    String area,
    @DecimalMin(value = "-90.0", message = "Latitude must be at least -90")
    @DecimalMax(value = "90.0", message = "Latitude must be at most 90")
    Double latitude,
    @DecimalMin(value = "-180.0", message = "Longitude must be at least -180")
    @DecimalMax(value = "180.0", message = "Longitude must be at most 180")
    Double longitude,
    @Size(max = 255, message = "Location note must be 255 characters or fewer")
    String locationNote,
    @Size(max = 80, message = "Food type must be 80 characters or fewer")
    String foodType,
    LocalDateTime preparedTime,
    LocalDateTime expiryTime,
    @Size(max = 120, message = "Medicine name must be 120 characters or fewer")
    String medicineName,
    LocalDate medicineExpiryDate,
    MedicineSealStatus medicineSealStatus,
    @Size(max = 64, message = "Batch number must be 64 characters or fewer")
    String batchNumber,
    @Size(max = 80, message = "Medicine category must be 80 characters or fewer")
    String medicineCategory,
    MedicineAccessType medicineAccessType,
    Boolean prescriptionRequired,
    Boolean requiresReceiverDelivery,
    List<String> photoUrls
) {
}

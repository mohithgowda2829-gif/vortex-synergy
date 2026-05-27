package com.vortexsynergy.backend.model;

import com.vortexsynergy.backend.model.enums.MedicineSealStatus;
import com.vortexsynergy.backend.model.enums.MedicineAccessType;
import com.vortexsynergy.backend.model.enums.ResourceStatus;
import com.vortexsynergy.backend.model.enums.ResourceType;
import com.vortexsynergy.backend.model.enums.VerificationStatus;
import jakarta.persistence.Column;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OrderColumn;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(
    name = "resources",
    indexes = {
        @Index(name = "idx_resources_type_status", columnList = "resource_type, status"),
        @Index(name = "idx_resources_city_area", columnList = "city, area"),
        @Index(name = "idx_resources_donor_status", columnList = "donor_id, status")
    }
)
public class Resource extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "donor_id", nullable = false)
    private User donor;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ResourceType resourceType;

    @Column(nullable = false)
    private String title;

    @Column(length = 1000)
    private String description;

    @Column(nullable = false)
    private Integer quantity;

    @Column(nullable = false)
    private Integer availableQuantity;

    @Column(nullable = false)
    private String unit;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ResourceStatus status;

    @Column(nullable = false)
    private String city;

    @Column(nullable = false)
    private String area;

    private Double latitude;

    private Double longitude;

    private String locationNote;

    private String foodType;

    private LocalDateTime preparedTime;

    private LocalDateTime expiresAt;

    private String medicineName;

    private LocalDate medicineExpiryDate;

    @Enumerated(EnumType.STRING)
    private MedicineSealStatus medicineSealStatus;

    private String batchNumber;

    private String medicineCategory;

    @Enumerated(EnumType.STRING)
    private MedicineAccessType medicineAccessType;

    private Boolean prescriptionRequired;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private VerificationStatus medicalVerificationStatus;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "medical_verified_by")
    private User medicalVerifiedBy;

    private Instant medicalVerifiedAt;

    private String medicalVerificationNote;

    private String verificationNotes;

    private Instant expiryWarningSentAt;

    @Column(name = "requires_volunteer_delivery", nullable = false)
    private boolean requiresReceiverDelivery;

    @Builder.Default
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "resource_photos", joinColumns = @JoinColumn(name = "resource_id"))
    @Column(name = "photo_url", nullable = false)
    @OrderColumn(name = "display_order")
    private List<String> photoUrls = new ArrayList<>();
}

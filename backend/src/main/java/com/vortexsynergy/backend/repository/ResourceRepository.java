package com.vortexsynergy.backend.repository;

import com.vortexsynergy.backend.dto.report.DonationReportRow;
import com.vortexsynergy.backend.dto.report.ExpiryReportRow;
import com.vortexsynergy.backend.dto.report.MedicineReportRow;
import com.vortexsynergy.backend.model.Resource;
import com.vortexsynergy.backend.model.enums.ResourceStatus;
import com.vortexsynergy.backend.model.enums.ResourceType;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ResourceRepository extends JpaRepository<Resource, UUID>, JpaSpecificationExecutor<Resource>, ResourceBrowseRepository {

    List<Resource> findByDonorIdOrderByCreatedAtDesc(UUID donorId);

    List<Resource> findAllByOrderByCreatedAtDesc();

    List<Resource> findByDonorIdAndResourceType(UUID donorId, ResourceType resourceType);

    List<Resource> findByMedicalVerifiedByIdAndResourceTypeOrderByMedicalVerifiedAtDesc(UUID reviewerId, ResourceType resourceType);

    long countByDonorIdAndStatus(UUID donorId, ResourceStatus status);

    long countByDonorIdAndStatusIn(UUID donorId, List<ResourceStatus> statuses);

    List<Resource> findByStatusInOrderByCreatedAtAsc(List<ResourceStatus> statuses);

    long countByStatus(ResourceStatus status);

    @Query("""
        select r from Resource r
        where r.status not in (com.vortexsynergy.backend.model.enums.ResourceStatus.EXPIRED,
                               com.vortexsynergy.backend.model.enums.ResourceStatus.CANCELLED,
                               com.vortexsynergy.backend.model.enums.ResourceStatus.CLAIMED)
        and (
            (r.resourceType = com.vortexsynergy.backend.model.enums.ResourceType.FOOD and r.expiresAt is not null and r.expiresAt <= :now)
            or
            (r.resourceType = com.vortexsynergy.backend.model.enums.ResourceType.MEDICINE and r.medicineExpiryDate is not null and r.medicineExpiryDate < :today)
        )
        """)
    List<Resource> findExpiredResources(@Param("now") LocalDateTime now, @Param("today") LocalDate today);

    @Query("""
        select new com.vortexsynergy.backend.dto.report.DonationReportRow(
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
        from Resource r
        join r.donor d
        order by r.createdAt desc
        """)
    List<DonationReportRow> findDonationReportRowsForAdmin();

    @Query("""
        select new com.vortexsynergy.backend.dto.report.ExpiryReportRow(
            r.id,
            r.title,
            r.resourceType,
            r.status,
            r.city,
            r.area,
            r.expiresAt,
            r.medicineExpiryDate
        )
        from Resource r
        where r.status = com.vortexsynergy.backend.model.enums.ResourceStatus.EXPIRED
        order by r.updatedAt desc
        """)
    List<ExpiryReportRow> findExpiryReportRows();

    @Query("""
        select new com.vortexsynergy.backend.dto.report.MedicineReportRow(
            r.id,
            r.title,
            r.medicineName,
            r.medicineCategory,
            r.medicineAccessType,
            r.prescriptionRequired,
            r.medicalVerificationStatus,
            coalesce(r.verificationNotes, r.medicalVerificationNote)
        )
        from Resource r
        where r.resourceType = com.vortexsynergy.backend.model.enums.ResourceType.MEDICINE
          and r.status <> com.vortexsynergy.backend.model.enums.ResourceStatus.CANCELLED
        order by r.createdAt desc
        """)
    List<MedicineReportRow> findMedicineReportRows();
}

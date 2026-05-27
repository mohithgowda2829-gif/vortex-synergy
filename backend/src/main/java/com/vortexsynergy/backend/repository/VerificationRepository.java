package com.vortexsynergy.backend.repository;

import com.vortexsynergy.backend.model.Verification;
import com.vortexsynergy.backend.model.enums.VerificationType;
import com.vortexsynergy.backend.model.enums.VerificationStatus;
import com.vortexsynergy.backend.model.enums.VerificationTargetType;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface VerificationRepository extends JpaRepository<Verification, UUID> {

    List<Verification> findByStatusOrderByCreatedAtAsc(VerificationStatus status);

    Optional<Verification> findFirstByTargetTypeAndTargetIdAndVerificationTypeOrderByCreatedAtDesc(
        VerificationTargetType targetType,
        UUID targetId,
        VerificationType verificationType
    );

    List<Verification> findByTargetTypeAndTargetId(VerificationTargetType targetType, UUID targetId);

    long countByStatus(VerificationStatus status);

    long countByReviewedByIdAndStatusAndVerificationType(UUID reviewedById, VerificationStatus status, VerificationType verificationType);
}

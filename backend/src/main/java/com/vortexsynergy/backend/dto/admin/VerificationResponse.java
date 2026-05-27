package com.vortexsynergy.backend.dto.admin;

import com.vortexsynergy.backend.model.Verification;
import com.vortexsynergy.backend.model.enums.VerificationStatus;
import com.vortexsynergy.backend.model.enums.VerificationTargetType;
import com.vortexsynergy.backend.model.enums.VerificationType;
import java.time.Instant;
import java.util.UUID;

public record VerificationResponse(
    UUID id,
    VerificationTargetType targetType,
    UUID targetId,
    VerificationType verificationType,
    VerificationStatus status,
    String subjectName,
    String note,
    Instant createdAt,
    Instant reviewedAt
) {
    public static VerificationResponse from(Verification verification, String subjectName) {
        return new VerificationResponse(
            verification.getId(),
            verification.getTargetType(),
            verification.getTargetId(),
            verification.getVerificationType(),
            verification.getStatus(),
            subjectName,
            verification.getNote(),
            verification.getCreatedAt(),
            verification.getReviewedAt()
        );
    }
}

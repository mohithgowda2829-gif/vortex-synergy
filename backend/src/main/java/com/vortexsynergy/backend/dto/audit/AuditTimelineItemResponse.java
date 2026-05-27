package com.vortexsynergy.backend.dto.audit;

import com.vortexsynergy.backend.model.AuditLog;
import java.time.Instant;
import java.util.UUID;

public record AuditTimelineItemResponse(
    UUID id,
    String actorName,
    String action,
    String targetType,
    String targetId,
    String details,
    String metadataJson,
    Instant createdAt
) {
    public static AuditTimelineItemResponse from(AuditLog auditLog) {
        return new AuditTimelineItemResponse(
            auditLog.getId(),
            auditLog.getActor() != null ? auditLog.getActor().getFullName() : "System",
            auditLog.getAction(),
            auditLog.getTargetType(),
            auditLog.getTargetId(),
            auditLog.getDetails(),
            auditLog.getMetadataJson(),
            auditLog.getCreatedAt()
        );
    }
}

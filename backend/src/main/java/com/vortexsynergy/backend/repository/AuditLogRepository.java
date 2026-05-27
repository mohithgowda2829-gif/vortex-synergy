package com.vortexsynergy.backend.repository;

import com.vortexsynergy.backend.model.AuditLog;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AuditLogRepository extends JpaRepository<AuditLog, UUID> {

    List<AuditLog> findByTargetTypeAndTargetIdOrderByCreatedAtAsc(String targetType, String targetId);

    List<AuditLog> findByTargetTypeAndTargetIdInOrderByCreatedAtAsc(String targetType, Collection<String> targetIds);
}

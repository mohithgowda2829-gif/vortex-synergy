package com.vortexsynergy.backend.service;

import com.vortexsynergy.backend.model.AuditLog;
import com.vortexsynergy.backend.model.User;
import com.vortexsynergy.backend.repository.AuditLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuditService {

    private final AuditLogRepository auditLogRepository;

    public void log(User actor, String action, String targetType, String targetId, String details) {
        log(actor, action, targetType, targetId, details, null);
    }

    public void log(User actor, String action, String targetType, String targetId, String details, String metadataJson) {
        AuditLog log = AuditLog.builder()
            .actor(actor)
            .action(action)
            .targetType(targetType)
            .targetId(targetId)
            .details(details)
            .metadataJson(metadataJson)
            .build();
        auditLogRepository.save(log);
    }
}

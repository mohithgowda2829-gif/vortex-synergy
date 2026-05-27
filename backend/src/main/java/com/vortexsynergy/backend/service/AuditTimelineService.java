package com.vortexsynergy.backend.service;

import com.vortexsynergy.backend.dto.audit.AuditTimelineItemResponse;
import com.vortexsynergy.backend.exception.ForbiddenException;
import com.vortexsynergy.backend.exception.NotFoundException;
import com.vortexsynergy.backend.model.AuditLog;
import com.vortexsynergy.backend.model.Claim;
import com.vortexsynergy.backend.model.Resource;
import com.vortexsynergy.backend.model.User;
import com.vortexsynergy.backend.model.enums.Role;
import com.vortexsynergy.backend.repository.AuditLogRepository;
import com.vortexsynergy.backend.repository.ClaimRepository;
import com.vortexsynergy.backend.repository.ResourceRepository;
import com.vortexsynergy.backend.repository.UserRepository;
import com.vortexsynergy.backend.security.UserPrincipal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AuditTimelineService {

    private final AuditLogRepository auditLogRepository;
    private final ClaimRepository claimRepository;
    private final ResourceRepository resourceRepository;
    private final UserRepository userRepository;

    public List<AuditTimelineItemResponse> getClaimTimeline(UserPrincipal principal, UUID claimId) {
        Claim claim = claimRepository.findById(claimId)
            .orElseThrow(() -> new NotFoundException("Claim not found"));
        ensureClaimAccess(currentUser(principal), claim);

        return auditLogRepository.findByTargetTypeAndTargetIdOrderByCreatedAtAsc("CLAIM", claimId.toString()).stream()
            .map(AuditTimelineItemResponse::from)
            .toList();
    }

    public List<AuditTimelineItemResponse> getResourceTimeline(UserPrincipal principal, UUID resourceId) {
        Resource resource = resourceRepository.findById(resourceId)
            .orElseThrow(() -> new NotFoundException("Resource not found"));
        ensureResourceAccess(currentUser(principal), resource);

        List<AuditLog> logs = new ArrayList<>(
            auditLogRepository.findByTargetTypeAndTargetIdOrderByCreatedAtAsc("RESOURCE", resourceId.toString())
        );
        List<String> claimIds = claimRepository.findByResourceIdOrderByCreatedAtAsc(resourceId).stream()
            .map(Claim::getId)
            .map(UUID::toString)
            .toList();
        if (!claimIds.isEmpty()) {
            logs.addAll(auditLogRepository.findByTargetTypeAndTargetIdInOrderByCreatedAtAsc("CLAIM", claimIds));
        }

        return logs.stream()
            .sorted(Comparator.comparing(AuditLog::getCreatedAt))
            .map(AuditTimelineItemResponse::from)
            .toList();
    }

    private void ensureClaimAccess(User actor, Claim claim) {
        if (actor.getRole() == Role.ADMIN) {
            return;
        }
        boolean allowed = actor.getRole() == Role.DOCTOR_PHARMACIST
            || actor.getId().equals(claim.getReceiver().getId())
            || actor.getId().equals(claim.getResource().getDonor().getId());
        if (!allowed) {
            throw new ForbiddenException("You do not have access to this claim timeline");
        }
    }

    private void ensureResourceAccess(User actor, Resource resource) {
        if (actor.getRole() == Role.ADMIN || actor.getRole() == Role.DOCTOR_PHARMACIST) {
            return;
        }
        if (!actor.getId().equals(resource.getDonor().getId())) {
            throw new ForbiddenException("You do not have access to this resource timeline");
        }
    }

    private User currentUser(UserPrincipal principal) {
        return userRepository.findById(principal.getId())
            .orElseThrow(() -> new NotFoundException("User not found"));
    }
}

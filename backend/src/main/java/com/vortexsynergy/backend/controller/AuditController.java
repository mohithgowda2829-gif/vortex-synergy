package com.vortexsynergy.backend.controller;

import com.vortexsynergy.backend.dto.audit.AuditTimelineItemResponse;
import com.vortexsynergy.backend.security.UserPrincipal;
import com.vortexsynergy.backend.service.AuditTimelineService;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/audit")
@RequiredArgsConstructor
public class AuditController {

    private final AuditTimelineService auditTimelineService;

    @GetMapping("/resource/{resourceId}")
    public List<AuditTimelineItemResponse> resourceTimeline(
        @AuthenticationPrincipal UserPrincipal principal,
        @PathVariable UUID resourceId
    ) {
        return auditTimelineService.getResourceTimeline(principal, resourceId);
    }

    @GetMapping("/claim/{claimId}")
    public List<AuditTimelineItemResponse> claimTimeline(
        @AuthenticationPrincipal UserPrincipal principal,
        @PathVariable UUID claimId
    ) {
        return auditTimelineService.getClaimTimeline(principal, claimId);
    }
}

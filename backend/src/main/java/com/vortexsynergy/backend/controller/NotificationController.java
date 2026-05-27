package com.vortexsynergy.backend.controller;

import com.vortexsynergy.backend.dto.notification.NotificationResponse;
import com.vortexsynergy.backend.dto.notification.NotificationSummaryResponse;
import com.vortexsynergy.backend.security.UserPrincipal;
import com.vortexsynergy.backend.service.NotificationService;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping("/my")
    public List<NotificationResponse> myNotifications(@AuthenticationPrincipal UserPrincipal principal) {
        return notificationService.getMyNotifications(principal);
    }

    @GetMapping("/summary")
    public NotificationSummaryResponse summary(@AuthenticationPrincipal UserPrincipal principal) {
        return notificationService.getSummary(principal);
    }

    @PatchMapping("/{notificationId}/read")
    public NotificationResponse markRead(
        @AuthenticationPrincipal UserPrincipal principal,
        @PathVariable UUID notificationId
    ) {
        return notificationService.markAsRead(principal, notificationId);
    }

    @PatchMapping("/read-all")
    public NotificationSummaryResponse markAllRead(@AuthenticationPrincipal UserPrincipal principal) {
        return notificationService.markAllAsRead(principal);
    }
}

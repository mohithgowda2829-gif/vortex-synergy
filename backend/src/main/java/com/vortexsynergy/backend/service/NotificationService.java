package com.vortexsynergy.backend.service;

import com.vortexsynergy.backend.dto.notification.NotificationResponse;
import com.vortexsynergy.backend.dto.notification.NotificationSummaryResponse;
import com.vortexsynergy.backend.exception.ForbiddenException;
import com.vortexsynergy.backend.exception.NotFoundException;
import com.vortexsynergy.backend.model.Notification;
import com.vortexsynergy.backend.model.User;
import com.vortexsynergy.backend.model.enums.NotificationType;
import com.vortexsynergy.backend.repository.NotificationRepository;
import com.vortexsynergy.backend.repository.UserRepository;
import com.vortexsynergy.backend.security.UserPrincipal;
import jakarta.transaction.Transactional;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    @Transactional
    public List<NotificationResponse> getMyNotifications(UserPrincipal principal) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(principal.getId(), PageRequest.of(0, 100)).stream()
            .map(NotificationResponse::from)
            .toList();
    }

    @Transactional
    public NotificationSummaryResponse getSummary(UserPrincipal principal) {
        return new NotificationSummaryResponse(notificationRepository.countByUserIdAndReadFalse(principal.getId()));
    }

    @Transactional
    public NotificationResponse markAsRead(UserPrincipal principal, UUID notificationId) {
        Notification notification = notificationRepository.findById(notificationId)
            .orElseThrow(() -> new NotFoundException("Notification not found"));
        if (!notification.getUser().getId().equals(principal.getId())) {
            throw new ForbiddenException("You cannot update this notification");
        }

        notification.setRead(true);
        notificationRepository.save(notification);
        return NotificationResponse.from(notification);
    }

    @Transactional
    public NotificationSummaryResponse markAllAsRead(UserPrincipal principal) {
        List<Notification> notifications = notificationRepository.findByUserIdOrderByCreatedAtDesc(principal.getId(), PageRequest.of(0, 500));
        for (Notification notification : notifications) {
            notification.setRead(true);
        }
        notificationRepository.saveAll(notifications);
        return new NotificationSummaryResponse(0);
    }

    @Transactional
    public void notifyUser(User user, NotificationType type, String title, String message) {
        if (user == null) {
            return;
        }
        notificationRepository.save(Notification.builder()
            .user(user)
            .type(type)
            .title(title)
            .message(message)
            .read(false)
            .build());
    }

    @Transactional
    public void notifyUsers(Collection<User> users, NotificationType type, String title, String message) {
        if (users == null) {
            return;
        }
        users.stream()
            .filter(user -> user != null)
            .forEach(user -> notifyUser(user, type, title, message));
    }

    public User findUser(UUID userId) {
        return userRepository.findById(userId)
            .orElseThrow(() -> new NotFoundException("User not found"));
    }
}

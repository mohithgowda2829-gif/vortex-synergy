package com.vortexsynergy.backend.service;

import com.vortexsynergy.backend.model.Resource;
import com.vortexsynergy.backend.model.User;
import com.vortexsynergy.backend.model.enums.ClaimStatus;
import com.vortexsynergy.backend.model.enums.ResourceType;
import com.vortexsynergy.backend.repository.ClaimRepository;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class PriorityService {

    private final ClaimRepository claimRepository;

    @Value("${app.claim.fairness-window-days}")
    private long fairnessWindowDays;

    public PriorityResult calculate(Resource resource, User receiver, boolean urgentNeed, boolean vulnerableReceiver) {
        int score = 0;
        List<String> reasons = new ArrayList<>();

        if (urgentNeed && resource.getResourceType() == ResourceType.MEDICINE) {
            score += 40;
            reasons.add("urgent medical need");
        }

        if (vulnerableReceiver) {
            score += 25;
            reasons.add("vulnerable receiver category");
        }

        if (isHighExpiry(resource)) {
            score += 20;
            reasons.add("high-expiry resource");
        }

        long recentClaims = claimRepository.countClaimsForReceiverSince(
            receiver.getId(),
            Set.of(ClaimStatus.RESERVED, ClaimStatus.CLAIMED, ClaimStatus.EXPIRED),
            Instant.now().minus(Duration.ofDays(fairnessWindowDays))
        );
        if (recentClaims >= 3) {
            score -= 15;
            reasons.add("fairness penalty for frequent recent claims");
        } else if (recentClaims >= 1) {
            score -= 5;
            reasons.add("light fairness adjustment");
        }

        if (reasons.isEmpty()) {
            reasons.add("standard priority profile");
        }

        return new PriorityResult(score, String.join(", ", reasons));
    }

    private boolean isHighExpiry(Resource resource) {
        if (resource.getResourceType() == ResourceType.FOOD) {
            return resource.getExpiresAt() != null
                && resource.getExpiresAt().isBefore(LocalDateTime.now().plusHours(6));
        }

        return resource.getMedicineExpiryDate() != null
            && !resource.getMedicineExpiryDate().isAfter(LocalDate.now(ZoneId.systemDefault()).plusDays(7));
    }

    public record PriorityResult(int score, String explanation) {
    }
}

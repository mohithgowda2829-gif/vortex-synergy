package com.vortexsynergy.backend.dto.dashboard;

public record RoleDashboardResponse(
    String role,
    long unreadNotifications,
    long activeDonations,
    long claimedDonations,
    long expiredDonations,
    long assignedDeliveryCount,
    long activeClaims,
    long completedClaims,
    long activeDeliveryCount,
    long completedDeliveryCount,
    long urgentClaimCount,
    long pendingVerificationCount,
    long approvedVerificationCount,
    long rejectedVerificationCount,
    long pendingUserApprovalCount,
    long moderatedResourceCount,
    long activeSystemDeliveryCount,
    long totalMealsSaved,
    long medicineKitsDistributed
) {
}

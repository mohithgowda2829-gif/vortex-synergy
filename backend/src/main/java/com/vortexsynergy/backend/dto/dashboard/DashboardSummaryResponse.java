package com.vortexsynergy.backend.dto.dashboard;

public record DashboardSummaryResponse(
    long totalMealsSaved,
    long medicineKitsDistributed,
    long donorCount,
    long completedClaims,
    long expiredResourcesPreventedFromMisuse
) {
}

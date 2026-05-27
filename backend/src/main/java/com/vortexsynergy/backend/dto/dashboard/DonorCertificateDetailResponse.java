package com.vortexsynergy.backend.dto.dashboard;

import java.time.Instant;

public record DonorCertificateDetailResponse(
    String donorName,
    long numberOfContributions,
    long impactCount,
    String certificateNumber,
    Instant issuedAt,
    String issuedBy,
    String programName,
    String statement
) {
}
